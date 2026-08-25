<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class AIController
{
    private const DAILY_LIMIT = 30;
    private const MODEL = 'google/gemma-4-31b-it';
    private const ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';

    private static function checkLimit(int $uid): bool
    {
        $stmt = Database::get()->prepare(
            'SELECT COUNT(*) c FROM ai_logs WHERE user_id = ? AND created_at >= CURDATE()'
        );
        $stmt->execute([$uid]);
        return (int)$stmt->fetch()['c'] < self::DAILY_LIMIT;
    }

    /**
     * Read the NVIDIA key through the project's Database key provider.
     * Do NOT hardcode an API key in this file.
     */
    private static function getNvidiaKey(): string
    {
        return trim((string) Database::nvidiaApiKey());
    }

    /**
     * Call NVIDIA Gemma 4 using the OpenAI-compatible endpoint.
     * Returns null only when the request failed or no usable content was returned.
     */
    private static function callNvidia(array $messages): ?string
    {
        $key = self::getNvidiaKey();

        if ($key === '') {
            error_log('AIController: NVIDIA API key is empty.');
            return null;
        }

        $payload = json_encode([
            'model' => self::MODEL,
            'messages' => $messages,
            'max_tokens' => 512,
            'temperature' => 0.2,
            'stream' => false,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        if ($payload === false) {
            error_log('AIController: JSON encode failed: ' . json_last_error_msg());
            return null;
        }

        $ch = curl_init(self::ENDPOINT);

        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => [
                'Authorization: Bearer ' . $key,
                'Content-Type: application/json',
                'Accept: application/json',
            ],
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_TIMEOUT => 90,
            CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
            CURLOPT_USERAGENT => 'Vetri-TNPSC-App/1.0',
        ]);

        $res = curl_exec($ch);
        $errno = curl_errno($ch);
        $error = curl_error($ch);
        $http = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $total = (float) curl_getinfo($ch, CURLINFO_TOTAL_TIME);
        curl_close($ch);

        if ($errno !== 0) {
            error_log(sprintf(
                'AIController: NVIDIA cURL error=%d http=%d time=%.3fs message=%s',
                $errno,
                $http,
                $total,
                $error
            ));
            return null;
        }

        if ($http < 200 || $http >= 300) {
            $safeBody = is_string($res) ? mb_substr($res, 0, 1000) : '';
            error_log(sprintf(
                'AIController: NVIDIA HTTP %d response=%s',
                $http,
                $safeBody
            ));
            return null;
        }

        if (!is_string($res) || trim($res) === '') {
            error_log('AIController: NVIDIA returned an empty response.');
            return null;
        }

        $data = json_decode($res, true);

        if (!is_array($data)) {
            error_log('AIController: Invalid NVIDIA JSON: ' . mb_substr($res, 0, 1000));
            return null;
        }

        $content = $data['choices'][0]['message']['content'] ?? null;

        if (!is_string($content)) {
            error_log('AIController: NVIDIA response has no choices[0].message.content: ' .
                mb_substr(json_encode($data, JSON_UNESCAPED_UNICODE), 0, 1000));
            return null;
        }

        // Remove reasoning wrappers if the model happens to return them.
        $content = preg_replace('/<think>.*?<\/think>/si', '', $content);
        $content = trim((string) $content);

        if ($content === '') {
            return 'மன்னிக்கவும், பதில் முழுமையாக கிடைக்கவில்லை. மீண்டும் கேளுங்கள் 🙏';
        }

        return $content;
    }

    private static function json(array $data, int $status = 200): void
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    private static function systemPrompt(): array
    {
        return [
            'role' => 'system',
            'content' =>
                'நீங்கள் "வெற்றி TNPSC" செயலியின் AI ஆசிரியர். '
              . 'TNPSC தேர்வுக்குத் தயாராகும் மாணவர்களுக்கு தமிழில் எளிமையாகவும் '
              . 'சுருக்கமாகவும், அதிகபட்சம் 150 சொற்களுக்குள் விளக்குங்கள். '
              . 'சமச்சீர் பாடநூல் அடிப்படையில் பதிலளிக்கவும். '
              . 'குறிப்பிட்ட பெயர்கள், தேதிகள், புள்ளிவிவரங்கள் அல்லது வரலாற்று விவரங்கள் '
              . 'உறுதியாகத் தெரியாவிட்டால் கற்பனை செய்து பதிலளிக்காதீர்கள். '
              . '"இதற்கான உறுதியான தகவல் என்னிடம் இல்லை; நம்பகமான மூலத்தில் சரிபார்க்கவும்" '
              . 'என்று நேர்மையாகக் கூறுங்கள். '
              . 'ஒரே கருத்தை மீண்டும் மீண்டும் சொல்லாதீர்கள். நேரடியாக பதிலைத் தொடங்குங்கள்.'
        ];
    }

    /** POST /api/ai/chat — {messages:[{role,content},...]} */
    public static function chat(): void
    {
        $uid = JWT::userIdFromHeader();

        // IMPORTANT: This 401 is JWT authentication, not NVIDIA authentication.
        if (!$uid) {
            self::json(['error' => 'Unauthorized'], 401);
            return;
        }

        if (!self::checkLimit($uid)) {
            self::json([
                'error' => 'இன்றைய AI கேள்வி வரம்பு (30) முடிந்தது. நாளை மீண்டும்! 🙏'
            ], 429);
            return;
        }

        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        $history = array_slice($b['messages'] ?? [], -8);

        $clean = [];
        foreach ($history as $m) {
            $role = $m['role'] ?? '';
            $content = $m['content'] ?? '';

            if (in_array($role, ['user', 'assistant'], true) && is_string($content) && trim($content) !== '') {
                $clean[] = [
                    'role' => $role,
                    'content' => mb_substr($content, 0, 2000)
                ];
            }
        }

        if (!$clean) {
            self::json(['error' => 'messages required'], 422);
            return;
        }

        $reply = self::callNvidia(array_merge([self::systemPrompt()], $clean));

        if ($reply === null) {
            self::json([
                'error' => 'AI சேவை தற்காலிகமாக கிடைக்கவில்லை. சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.'
            ], 502);
            return;
        }

        $last = end($clean);
        $log = Database::get()->prepare(
            'INSERT INTO ai_logs (user_id, kind, chars_in, chars_out) VALUES (?,?,?,?)'
        );
        $log->execute([
            $uid,
            'chat',
            mb_strlen($last['content'] ?? ''),
            mb_strlen($reply)
        ]);

        self::json(['reply' => $reply]);
    }

    /** POST /api/ai/explain — {question_id} */
    public static function explain(): void
    {
        $uid = JWT::userIdFromHeader();

        if (!$uid) {
            self::json(['error' => 'Unauthorized'], 401);
            return;
        }

        if (!self::checkLimit($uid)) {
            self::json([
                'error' => 'இன்றைய AI வரம்பு முடிந்தது. நாளை மீண்டும்! 🙏'
            ], 429);
            return;
        }

        $b = json_decode(file_get_contents('php://input'), true) ?: [];

        $stmt = Database::get()->prepare(
            'SELECT question_ta, options_ta, correct_option, explanation_ta, book_name_ta, unit
             FROM questions WHERE id = ? AND is_active = 1'
        );
        $stmt->execute([(int)($b['question_id'] ?? 0)]);
        $q = $stmt->fetch();

        if (!$q) {
            self::json(['error' => 'Question not found'], 404);
            return;
        }

        $opts = json_decode($q['options_ta'], true);
        if (!is_array($opts)) {
            self::json(['error' => 'Question options are invalid'], 500);
            return;
        }

        $correctIndex = (int)$q['correct_option'];
        $correctAnswer = $opts[$correctIndex] ?? '';

        $prompt = "TNPSC கேள்வி: {$q['question_ta']}\n"
                . "விருப்பங்கள்: " . implode(' | ', $opts) . "\n"
                . "சரியான விடை: {$correctAnswer}\n"
                . "பாடம்: {$q['unit']} ({$q['book_name_ta']})\n\n"
                . "இந்த கேள்வியை மாணவருக்கு விளக்குங்கள்:\n"
                . "1) ஏன் இது சரியான விடை\n"
                . "2) மற்ற விருப்பங்கள் ஏன் தவறு\n"
                . "3) நினைவில் வைக்க ஒரு எளிய குறிப்பு.";

        $reply = self::callNvidia([
            self::systemPrompt(),
            ['role' => 'user', 'content' => $prompt]
        ]);

        if ($reply === null) {
            self::json([
                'reply' => '💡 ' . ($q['explanation_ta'] ?: 'விளக்கம் தற்போது இல்லை.')
            ]);
            return;
        }

        $log = Database::get()->prepare(
            'INSERT INTO ai_logs (user_id, kind, chars_in, chars_out) VALUES (?,?,?,?)'
        );
        $log->execute([
            $uid,
            'explain',
            mb_strlen($prompt),
            mb_strlen($reply)
        ]);

        self::json(['reply' => $reply]);
    }
}
