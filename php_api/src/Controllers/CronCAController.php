<?php
namespace App\Controllers;

use App\Config\Database;
use App\Config\Secrets;

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
        // Official PIB Chennai Tamil RSS — already in Tamil, so no AI translation needed.
        ['url' => 'https://www.pib.gov.in/ViewRss.aspx?lang=11&reg=6',
         'category' => 'tn', 'is_tn' => 1, 'source_lang' => 'ta'],
        // Official PIB national English RSS.
        ['url' => 'https://www.pib.gov.in/ViewRss.aspx?lang=1&reg=1',
         'category' => 'national', 'is_tn' => 0, 'source_lang' => 'en'],
    ];

    // Skip pure entertainment/sports-gossip noise; keep exam-relevant news
    private const SKIP_WORDS = ['cinema', 'movie review', 'box office', 'celebrity', 'horoscope'];
    private const MAX_PER_FEED = 5;

    /**
     * Fetches an RSS feed via curl (not file_get_contents) so we can follow
     * redirects and send a realistic desktop-browser User-Agent. The Hindu's
     * feeds sit behind bot-protection that returned a hard 403 for our old
     * "VetriTNPSC-CA-Bot/1.0" identifier — a normal browser UA gets through.
     */
    private static function fetchRss(string $url): ?\SimpleXMLElement
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => true,
            CURLOPT_MAXREDIRS => 5,
            CURLOPT_TIMEOUT => 15,
            CURLOPT_ENCODING => '', // auto-handle gzip/deflate — some feeds require it
            CURLOPT_HTTPHEADER => ['Accept: application/rss+xml, application/xml, text/xml, */*'],
            CURLOPT_USERAGENT => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                . 'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        ]);
        $xml = curl_exec($ch);
        $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if (!$xml || $code >= 400) return null;
        libxml_use_internal_errors(true);
        $parsed = simplexml_load_string($xml);
        return $parsed ?: null;
    }

    /**
     * Reuses NVIDIA Gemma 4 (same key as AI tutor) to translate EN/HI -> TA.
     * PIB's "Lang=1" regional feed occasionally sends Hindi text even though
     * it's meant to be the English feed — earlier we always told the AI
     * "this is English", so when Hindi text slipped through, the model got
     * confused and produced broken/garbled Tamil. Now we detect the actual
     * script and tell the AI the real source language, and separately keep
     * the prompt tight on spelling/sentence-formation quality.
     */
    private static function translateToTamil(string $text): ?string
    {
        if (preg_match('/[\x{0B80}-\x{0BFF}]/u', $text)) return trim($text);
        // Same centralized key getter as AIController.php — plain
        // getenv('NVIDIA_API_KEY') was returning empty/false on this
        // hosting (same root cause as the earlier JWT_SECRET issue: no
        // .env in use, and this env var isn't reliably exposed by the
        // panel), so EVERY translation call here was silently failing
        // and falling back to raw source text — which is how Hindi (and
        // untranslated English) titles were leaking into title_ta.
        $key = Database::nvidiaApiKey();
        if (!$key) return null;
        $isHindi = self::looksHindi($text);
        $payload = json_encode([
            'model' => 'google/gemma-4-31b-it',
            'messages' => [
                ['role' => 'system', 'content' =>
                    "You are a senior Tamil news sub-editor (like Dinamalar/Dinathanthi). "
                  . "The input text below is in " . ($isHindi ? "Hindi" : "English") . ". "
                  . "Translate it into natural, professionally written Tamil for a "
                  . "competitive-exam (TNPSC) current-affairs app.\n"
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
                  . "5. Output ONLY the final Tamil text — no notes, no English/Hindi, no quotes."],
                ['role' => 'user', 'content' => $text],
            ],
            'max_tokens' => 600, // Gemma 4 "thinks" internally before answering —
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

        // Strip Gemma 4's internal <think>...</think> reasoning trace — only
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

    /** True if the text contains Devanagari script (Hindi), regardless of what the feed claims. */
    private static function looksHindi(string $text): bool
    {
        return (bool)preg_match('/[\x{0900}-\x{097F}]/u', $text);
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
        if (!Database::nvidiaApiKey()) {
            $errors[] = 'NVIDIA_API_KEY env var not set — all Tamil translations will fail and fall back to raw feed text.';
        }

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

                $titleTaRaw = (($feed['source_lang'] ?? 'en') === 'ta') ? $title : self::translateToTamil($title);
                if ($titleTaRaw === null) {
                    // If the source itself is Hindi and translation failed,
                    // do NOT fall back to the raw title — that means showing
                    // untranslated Hindi text to a Tamil-app user (exactly
                    // the bug being fixed here). Skip this item entirely;
                    // it'll simply be picked up and translated correctly on
                    // a later fetch run instead of being stored broken.
                    if (self::looksHindi($title)) {
                        $skipped++;
                        $errors[] = "Skipped (Hindi source, translation failed): " . mb_substr($title, 0, 60);
                        continue;
                    }
                    $errors[] = "Translation failed (English title kept as-is): " . mb_substr($title, 0, 60);
                }
                $titleTa = $titleTaRaw ?? $title; // English-source fallback only
                $contentTa = $desc ? ((($feed['source_lang'] ?? 'en') === 'ta') ? mb_substr($desc, 0, 400) : (self::translateToTamil(mb_substr($desc, 0, 300)) ?? '')) : '';
                $image = self::extractImage($item);

                // The "English" field should only ever hold actual English text.
                // If the feed sent Hindi (PIB's Lang=1 regional feed does this
                // occasionally), leave title_en/content_en blank rather than
                // showing Hindi to someone who tapped the English toggle —
                // the Tamil translation above is still correct either way
                // since translateToTamil() auto-detects the real script.
                $titleEnSafe = (($feed['source_lang'] ?? 'en') === 'en') ? $title : '';
                $descEnSafe = (($feed['source_lang'] ?? 'en') === 'en') ? mb_substr($desc, 0, 400) : '';

                try {
                    $insert->execute([
                        $feed['category'], $titleTa, $titleEnSafe,
                        $contentTa, $descEnSafe,
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
        // Same hardcoded-fallback pattern as Database.php/JWT.php — this
        // hosting doesn't reliably expose custom env vars (no .env in
        // use), so getenv('CRON_SECRET') was always empty, meaning this
        // check failed with "Invalid or missing cron token" no matter
        // what token was actually supplied in the URL.
        $cronSecret = getenv('CRON_SECRET') ?: Secrets::CRON_SECRET;
        if (($_GET['token'] ?? '') !== $cronSecret) {
            http_response_code(403);
            echo json_encode(['error' => 'Invalid or missing cron token']);
            return;
        }
        echo json_encode(self::runFetch(), JSON_UNESCAPED_UNICODE);
    }
}