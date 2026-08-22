<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class AIController
{
    private const DAILY_LIMIT = 30; // per user per day
    private const MODEL = 'sarvamai/sarvam-m';
    private const ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';

    private static function checkLimit(int $uid): bool
    {
        $stmt = Database::get()->prepare(
            'SELECT COUNT(*) c FROM ai_logs WHERE user_id = ? AND created_at >= CURDATE()');
        $stmt->execute([$uid]);
        return (int)$stmt->fetch()['c'] < self::DAILY_LIMIT;
    }

    private static function callNvidia(array $messages): ?string
    {
        $key = getenv('NVIDIA_API_KEY');
        if (!$key) return null;
        $payload = json_encode([
            'model' => self::MODEL,
            'messages' => $messages,
            'max_tokens' => 1536, // sarvam-m is a reasoning model — needs room to
                                  // "think" internally before the final answer;
                                  // 600 was cutting responses off mid-thought.
            'temperature' => 0.4,
        ], JSON_UNESCAPED_UNICODE);
        $ch = curl_init(self::ENDPOINT);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $key,
            ],
            CURLOPT_TIMEOUT => 60,
        ]);
        $res = curl_exec($ch);
        curl_close($ch);
        if (!$res) return null;
        $data = json_decode($res, true);
        $content = $data['choices'][0]['message']['content'] ?? null;
        if ($content === null) return null;

        // sarvam-m emits its internal reasoning wrapped in <think>...</think>
        // before the real answer. Strip it — the user should only ever see
        // the final answer, never the model's scratch-work.
        $content = preg_replace('/<think>.*?<\/think>/s', '', $content);
        $content = trim($content);

        // Safety net: if the whole reply was reasoning with no closing tag
        // (got cut off mid-thought even at the higher token limit), don't
        // show the garbled partial trace — ask the user to retry instead.
        if ($content === '' || str_contains($content, '<think>')) {
            return 'மன்னிக்கவும், பதில் முழுமையாக கிடைக்கவில்லை. மீண்டும் கேளுங்கள் 🙏';
        }
        return $content;
    }

    private static function systemPrompt(): array
    {
        return ['role' => 'system', 'content' =>
            'நீங்கள் "வெற்றி TNPSC" செயலியின் AI ஆசிரியர். TNPSC தேர்வுக்குத் தயாராகும் மாணவர்களுக்கு '
          . 'தமிழில் எளிமையாக, சுருக்கமாக (150 சொற்களுக்குள்) விளக்குங்கள். '
          . 'சமச்சீர் பாடநூல் அடிப்படையில் பதிலளிக்கவும். தேர்வு டிப்ஸ் தரலாம். '
          . '⚠️ மிக முக்கியம்: குறிப்பிட்ட பெயர்கள், தேதிகள், புள்ளிவிவரங்கள் அல்லது சிறு/குறிப்பிட்ட '
          . 'வரலாற்று விவரங்கள் பற்றி உறுதியாகத் தெரியாவிட்டால், அதை ஒருபோதும் கற்பனை செய்து '
          . 'பதிலளிக்காதீர்கள் — பொருத்தமற்ற எண்கள், தொடர்பில்லாத பெயர்கள் அல்லது தவறான தகவலை '
          . 'உருவாக்குவதைவிட "இதற்கான உறுதியான தகவல் என்னிடம் இல்லை, சமச்சீர் பாடநூல்/நம்பகமான '
          . 'மூலத்தில் சரிபார்க்கவும்" என நேர்மையாகக் கூறுங்கள்.'];
    }

    /** POST /api/ai/chat — {messages:[{role,content},...]} */
    public static function chat(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        if (!self::checkLimit($uid)) {
            http_response_code(429);
            echo json_encode(['error' => 'இன்றைய AI கேள்வி வரம்பு (30) முடிந்தது. நாளை மீண்டும்! 🙏'], JSON_UNESCAPED_UNICODE);
            return;
        }
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        $history = array_slice($b['messages'] ?? [], -8); // last 8 turns only
        $clean = [];
        foreach ($history as $m) {
            if (in_array($m['role'] ?? '', ['user','assistant']) && !empty($m['content'])) {
                $clean[] = ['role' => $m['role'], 'content' => mb_substr($m['content'], 0, 2000)];
            }
        }
        if (!$clean) { http_response_code(422); echo json_encode(['error' => 'messages required']); return; }

        $reply = self::callNvidia(array_merge([self::systemPrompt()], $clean));
        if ($reply === null) {
            http_response_code(502);
            echo json_encode(['error' => 'AI சேவை தற்காலிகமாக இல்லை'], JSON_UNESCAPED_UNICODE);
            return;
        }
        $log = Database::get()->prepare(
            'INSERT INTO ai_logs (user_id, kind, chars_in, chars_out) VALUES (?,?,?,?)');
        $log->execute([$uid, 'chat', mb_strlen(end($clean)['content']), mb_strlen($reply)]);
        echo json_encode(['reply' => $reply], JSON_UNESCAPED_UNICODE);
    }

    /** POST /api/ai/explain — {question_id} → deep explanation */
    public static function explain(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        if (!self::checkLimit($uid)) {
            http_response_code(429);
            echo json_encode(['error' => 'இன்றைய AI வரம்பு முடிந்தது. நாளை மீண்டும்! 🙏'], JSON_UNESCAPED_UNICODE);
            return;
        }
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        $stmt = Database::get()->prepare(
            'SELECT question_ta, options_ta, correct_option, explanation_ta, book_name_ta, unit
             FROM questions WHERE id = ? AND is_active = 1');
        $stmt->execute([(int)($b['question_id'] ?? 0)]);
        $q = $stmt->fetch();
        if (!$q) { http_response_code(404); echo json_encode(['error' => 'Question not found']); return; }

        $opts = json_decode($q['options_ta'], true);
        $prompt = "TNPSC கேள்வி: {$q['question_ta']}\n"
                . "விருப்பங்கள்: " . implode(' | ', $opts) . "\n"
                . "சரியான விடை: " . $opts[$q['correct_option']] . "\n"
                . "பாடம்: {$q['unit']} ({$q['book_name_ta']})\n\n"
                . "இந்த கேள்வியை மாணவருக்கு விரிவாக விளக்குங்கள்: "
                . "1) ஏன் இது சரியான விடை 2) மற்ற விருப்பங்கள் ஏன் தவறு "
                . "3) நினைவில் வைக்க ஒரு எளிய குறிப்பு (memory trick).";

        $reply = self::callNvidia([self::systemPrompt(),
            ['role' => 'user', 'content' => $prompt]]);
        if ($reply === null) {
            // Fallback: stored explanation
            echo json_encode(['reply' => '💡 ' . ($q['explanation_ta'] ?: 'விளக்கம் தற்போது இல்லை.')], JSON_UNESCAPED_UNICODE);
            return;
        }
        $log = Database::get()->prepare(
            'INSERT INTO ai_logs (user_id, kind, chars_in, chars_out) VALUES (?,?,?,?)');
        $log->execute([$uid, 'explain', mb_strlen($prompt), mb_strlen($reply)]);
        echo json_encode(['reply' => $reply], JSON_UNESCAPED_UNICODE);
    }
}
