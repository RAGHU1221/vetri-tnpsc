<?php
namespace App\Controllers;

use App\Config\Database;

/**
 * Daily Current-Affairs auto-fetch.
 * Triggered by an external free cron service (cron-job.org) hitting:
 *   GET /api/cron/fetch-ca?token=YOUR_CRON_SECRET
 * No Composer needed — SimpleXML (built into PHP) parses RSS.
 */
class CronCAController
{
    // Free, public RSS feeds — no API key required
    private const FEEDS = [
        ['url' => 'https://www.thehindu.com/news/national/tamil-nadu/feeder/default.rss',
         'category' => 'tn', 'is_tn' => 1],
        ['url' => 'https://pib.gov.in/RssMain.aspx?ModId=6&Lang=1&Regid=3',
         'category' => 'tn', 'is_tn' => 1],
        ['url' => 'https://www.thehindu.com/news/national/feeder/default.rss',
         'category' => 'national', 'is_tn' => 0],
        ['url' => 'https://www.thehindu.com/sci-tech/feeder/default.rss',
         'category' => 'science', 'is_tn' => 0],
    ];

    // Skip pure entertainment/sports-gossip noise; keep exam-relevant news
    private const SKIP_WORDS = ['cinema', 'movie review', 'box office', 'celebrity', 'horoscope'];
    private const MAX_PER_FEED = 5;

    private static function fetchRss(string $url): ?\SimpleXMLElement
    {
        $ctx = stream_context_create(['http' => [
            'timeout' => 12,
            'header' => "User-Agent: VetriTNPSC-CA-Bot/1.0\r\n",
        ]]);
        $xml = @file_get_contents($url, false, $ctx);
        if (!$xml) return null;
        libxml_use_internal_errors(true);
        $parsed = simplexml_load_string($xml);
        return $parsed ?: null;
    }

    /** Reuses NVIDIA Sarvam-M (same key as AI tutor) to translate EN -> TA */
    private static function translateToTamil(string $text): ?string
    {
        $key = getenv('NVIDIA_API_KEY');
        if (!$key) return null;
        $payload = json_encode([
            'model' => 'sarvamai/sarvam-m',
            'messages' => [
                ['role' => 'system', 'content' =>
                    'You are a translator. Translate the given English news headline into natural, '
                  . 'concise Tamil suitable for a competitive-exam current-affairs app. '
                  . 'Reply with ONLY the Tamil translation, nothing else.'],
                ['role' => 'user', 'content' => $text],
            ],
            'max_tokens' => 150,
            'temperature' => 0.2,
        ], JSON_UNESCAPED_UNICODE);
        $ch = curl_init('https://integrate.api.nvidia.com/v1/chat/completions');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Authorization: Bearer ' . $key],
            CURLOPT_TIMEOUT => 25,
        ]);
        $res = curl_exec($ch);
        curl_close($ch);
        if (!$res) return null;
        $data = json_decode($res, true);
        $ta = $data['choices'][0]['message']['content'] ?? null;
        return $ta ? trim($ta) : null;
    }

    private static function relevant(string $title): bool
    {
        $lower = mb_strtolower($title);
        foreach (self::SKIP_WORDS as $w) {
            if (str_contains($lower, $w)) return false;
        }
        return true;
    }

    /** GET /api/cron/fetch-ca?token=... */
    public static function fetchDaily(): void
    {
        if (($_GET['token'] ?? '') !== getenv('CRON_SECRET') || !getenv('CRON_SECRET')) {
            http_response_code(403);
            echo json_encode(['error' => 'Invalid or missing cron token']);
            return;
        }

        $db = Database::get();
        $check = $db->prepare('SELECT id FROM current_affairs WHERE source_url = ? LIMIT 1');
        $insert = $db->prepare(
            'INSERT INTO current_affairs (ca_date, category, title_ta, title_en, content_ta, content_en, is_tn, source_url)
             VALUES (CURDATE(), ?, ?, ?, ?, ?, ?, ?)');

        $added = 0; $skipped = 0; $errors = [];

        foreach (self::FEEDS as $feed) {
            $xml = self::fetchRss($feed['url']);
            if (!$xml || !isset($xml->channel->item)) {
                $errors[] = "Feed unreachable: {$feed['url']}";
                continue;
            }
            $count = 0;
            foreach ($xml->channel->item as $item) {
                if ($count >= self::MAX_PER_FEED) break;
                $title = trim((string)$item->title);
                $link = trim((string)$item->link);
                $desc = trim(strip_tags((string)$item->description));
                if ($title === '' || $link === '' || !self::relevant($title)) continue;

                $check->execute([$link]);
                if ($check->fetch()) { $skipped++; continue; } // already fetched before

                $titleTa = self::translateToTamil($title) ?? $title; // fallback: English if translate fails
                $contentTa = $desc ? (self::translateToTamil(mb_substr($desc, 0, 300)) ?? '') : '';

                try {
                    $insert->execute([
                        $feed['category'], $titleTa, $title,
                        $contentTa, mb_substr($desc, 0, 400),
                        $feed['is_tn'], $link,
                    ]);
                    $added++;
                } catch (\Throwable $e) {
                    $skipped++;
                    $errors[] = "Insert failed: " . mb_substr($title, 0, 60);
                }
                $count++;
            }
        }

        echo json_encode([
            'ok' => true,
            'date' => date('Y-m-d H:i'),
            'added' => $added,
            'skipped_existing' => $skipped,
            'feeds_checked' => count(self::FEEDS),
            'errors' => $errors,
        ], JSON_UNESCAPED_UNICODE);
    }
}
