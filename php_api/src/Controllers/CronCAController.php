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
         'category' => 'national', 'is_tn' => 0], // PIB carries central-govt/national
                                                    // announcements (ministries, PSUs like
                                                    // SAIL) even on its regional feed —
                                                    // was wrongly marked is_tn=1 before,
                                                    // causing national news to show under
                                                    // the "தமிழ்நாடு மட்டும்" filter.
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

    /**
     * Reuses NVIDIA Sarvam-M (same key as AI tutor) to translate EN -> TA.
     * Prompt tightened to specifically fight two recurring problems reported
     * by users: spelling mistakes and broken/incomplete sentence formation.
     */
    private static function translateToTamil(string $text): ?string
    {
        $key = getenv('NVIDIA_API_KEY');
        if (!$key) return null;
        $payload = json_encode([
            'model' => 'sarvamai/sarvam-m',
            'messages' => [
                ['role' => 'system', 'content' =>
                    "You are a senior Tamil news sub-editor (like Dinamalar/Dinathanthi). "
                  . "Translate the given English news text into natural, professionally "
                  . "written Tamil for a competitive-exam (TNPSC) current-affairs app.\n"
                  . "STRICT RULES:\n"
                  . "1. Correct Tamil spelling only — double-check every word before answering; "
                  . "no typos, no mixed-up வல்லினம்/மெல்லினம், no missing புள்ளி.\n"
                  . "2. Every sentence must be a complete, grammatically correct Tamil sentence "
                  . "with a proper subject-object-verb structure — never a literal word-by-word "
                  . "translation and never a half-finished sentence.\n"
                  . "3. Keep well-known proper nouns, place names, and official terms "
                  . "(ministry/scheme/organisation names) as commonly printed in Tamil "
                  . "newspapers; do not invent alternate spellings for them.\n"
                  . "4. Use common written Tamil (எழுத்துத் தமிழ்), not spoken/colloquial style.\n"
                  . "5. Output ONLY the final Tamil text — no notes, no English, no quotes."],
                ['role' => 'user', 'content' => $text],
            ],
            'max_tokens' => 600, // sarvam-m "thinks" internally before answering —
                                 // 150 was cutting it off mid-thought, producing
                                 // broken/garbled partial-sentence translations.
            'temperature' => 0.15, // lower than before — less creative drift, fewer spelling slips
        ], JSON_UNESCAPED_UNICODE);
        $ch = curl_init('https://integrate.api.nvidia.com/v1/chat/completions');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Authorization: Bearer ' . $key],
            CURLOPT_TIMEOUT => 40,
        ]);
        $res = curl_exec($ch);
        curl_close($ch);
        if (!$res) return null;
        $data = json_decode($res, true);
        $ta = $data['choices'][0]['message']['content'] ?? null;
        if ($ta === null) return null;

        // Strip sarvam-m's internal <think>...</think> reasoning trace — only
        // the actual translation should ever be stored/shown.
        $ta = trim(preg_replace('/<think>.*?<\/think>/s', '', $ta));
        // Model occasionally wraps the answer in quotes despite instructions — strip them.
        $ta = trim($ta, "\"'“”‘’ \t\n\r");
        // Collapse accidental double spaces/newlines from the model output.
        $ta = trim(preg_replace('/[ \t]{2,}/', ' ', $ta));

        // If it's empty or still has an unclosed <think> tag, the translation
        // never completed — return null so the caller falls back to English
        // rather than storing a broken/garbled Tamil fragment.
        if ($ta === '' || str_contains($ta, '<think>')) return null;
        return $ta;
    }

    private static function relevant(string $title): bool
    {
        $lower = mb_strtolower($title);
        foreach (self::SKIP_WORDS as $w) {
            if (str_contains($lower, $w)) return false;
        }
        return true;
    }

    /**
     * Best-effort image URL for an RSS <item> — checks the standard
     * <enclosure> tag first, then the common Media RSS namespace tags
     * (<media:content>/<media:thumbnail>) that most news sites also send.
     */
    private static function extractImage(\SimpleXMLElement $item): ?string
    {
        if (isset($item->enclosure['url'])) {
            $type = (string)($item->enclosure['type'] ?? '');
            if ($type === '' || str_starts_with($type, 'image/')) {
                return (string)$item->enclosure['url'];
            }
        }
        $media = $item->children('http://search.yahoo.com/mrss/');
        if (isset($media->content['url'])) return (string)$media->content['url'];
        if (isset($media->thumbnail['url'])) return (string)$media->thumbnail['url'];
        return null;
    }

    /**
     * Core fetch logic, reusable both by the token-protected HTTP cron
     * endpoint (fetchDaily) and by CAController's automatic "no news for
     * today yet? fetch now" safety net — so daily updates still happen even
     * if the external cron-job.org schedule is never set up or fails.
     */
    public static function runFetch(): array
    {
        $db = Database::get();
        $check = $db->prepare('SELECT id FROM current_affairs WHERE source_url = ? LIMIT 1');
        $insert = $db->prepare(
            'INSERT INTO current_affairs (ca_date, category, title_ta, title_en, content_ta, content_en, is_tn, source_url, image_url)
             VALUES (CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?)');

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
                $image = self::extractImage($item);

                try {
                    $insert->execute([
                        $feed['category'], $titleTa, $title,
                        $contentTa, mb_substr($desc, 0, 400),
                        $feed['is_tn'], $link, $image,
                    ]);
                    $added++;
                } catch (\Throwable $e) {
                    $skipped++;
                    $errors[] = "Insert failed: " . mb_substr($title, 0, 60);
                }
                $count++;
            }
        }

        return [
            'ok' => true,
            'date' => date('Y-m-d H:i'),
            'added' => $added,
            'skipped_existing' => $skipped,
            'feeds_checked' => count(self::FEEDS),
            'errors' => $errors,
        ];
    }

    /** GET /api/cron/fetch-ca?token=... — manual / external cron-job.org trigger */
    public static function fetchDaily(): void
    {
        if (($_GET['token'] ?? '') !== getenv('CRON_SECRET') || !getenv('CRON_SECRET')) {
            http_response_code(403);
            echo json_encode(['error' => 'Invalid or missing cron token']);
            return;
        }
        echo json_encode(self::runFetch(), JSON_UNESCAPED_UNICODE);
    }
}
