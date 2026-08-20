<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

/**
 * Job/Exam Notifications — application links, vacancies, deadlines.
 *
 * IMPORTANT DESIGN CHOICE: application links & vacancy counts are safety-critical —
 * a wrong link or wrong number could genuinely mislead a student's application.
 * So: only is_verified=1 rows are shown to students. The admin panel is the primary,
 * reliable way to publish these (see Notifications tab). A best-effort cron
 * (checkNews) can DRAFT candidate entries from news mentions, but they land as
 * is_verified=0 and stay invisible until an admin reviews and confirms them —
 * auto-fetch never publishes unverified critical data directly to students.
 */
class NotificationController
{
    /** GET /api/notifications — public, verified only */
    public static function list(): void
    {
        $stmt = Database::get()->query(
            "SELECT id, exam_key, title_ta, title_en, vacancies, application_start,
                    application_end, exam_date, application_link, official_notification_link,
                    status, notes_ta, notes_en, updated_at
             FROM job_notifications
             WHERE is_verified = 1
             ORDER BY FIELD(status,'open','upcoming','closed'), application_end IS NULL, application_end ASC");
        echo json_encode(['notifications' => $stmt->fetchAll()], JSON_UNESCAPED_UNICODE);
    }

    /** GET /api/admin/notifications — admin sees everything incl. unverified drafts */
    public static function adminList(): void
    {
        if (!self::isAdmin()) return;
        $stmt = Database::get()->query(
            "SELECT * FROM job_notifications ORDER BY is_verified ASC, updated_at DESC");
        echo json_encode(['notifications' => $stmt->fetchAll()], JSON_UNESCAPED_UNICODE);
    }

    private static function isAdmin(): bool
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return false; }
        $chk = Database::get()->prepare('SELECT is_admin FROM users WHERE id = ?');
        $chk->execute([$uid]);
        if (!($chk->fetch()['is_admin'] ?? 0)) {
            http_response_code(403); echo json_encode(['error' => 'Admin only']); return false;
        }
        return true;
    }

    /** POST /api/admin/notifications/upsert — admin add/edit (this is the reliable path) */
    public static function upsert(): void
    {
        if (!self::isAdmin()) return;
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        if (empty($b['title_ta']) || empty($b['exam_key'])) {
            http_response_code(422); echo json_encode(['error' => 'exam_key & title_ta required']); return;
        }
        $db = Database::get();
        if (!empty($b['id'])) {
            $stmt = $db->prepare(
                "UPDATE job_notifications SET exam_key=?, title_ta=?, title_en=?, vacancies=?,
                    application_start=?, application_end=?, exam_date=?, application_link=?,
                    official_notification_link=?, status=?, is_verified=1, notes_ta=?, notes_en=?
                 WHERE id=?");
            $stmt->execute([
                $b['exam_key'], $b['title_ta'], $b['title_en'] ?? '', $b['vacancies'] ?: null,
                $b['application_start'] ?: null, $b['application_end'] ?: null, $b['exam_date'] ?: null,
                $b['application_link'] ?? '', $b['official_notification_link'] ?? '',
                $b['status'] ?? 'upcoming', $b['notes_ta'] ?? '', $b['notes_en'] ?? '', $b['id'],
            ]);
        } else {
            $stmt = $db->prepare(
                "INSERT INTO job_notifications (exam_key, title_ta, title_en, vacancies,
                    application_start, application_end, exam_date, application_link,
                    official_notification_link, status, is_verified, source, notes_ta, notes_en)
                 VALUES (?,?,?,?,?,?,?,?,?,?,1,'admin',?,?)");
            $stmt->execute([
                $b['exam_key'], $b['title_ta'], $b['title_en'] ?? '', $b['vacancies'] ?: null,
                $b['application_start'] ?: null, $b['application_end'] ?: null, $b['exam_date'] ?: null,
                $b['application_link'] ?? '', $b['official_notification_link'] ?? '',
                $b['status'] ?? 'upcoming', $b['notes_ta'] ?? '', $b['notes_en'] ?? '',
            ]);
        }
        echo json_encode(['ok' => true]);
    }

    /** POST /api/admin/notifications/verify — approve a draft (id, verified bool) */
    public static function verify(): void
    {
        if (!self::isAdmin()) return;
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        if (empty($b['id'])) { http_response_code(422); echo json_encode(['error' => 'id required']); return; }
        $stmt = Database::get()->prepare('UPDATE job_notifications SET is_verified = ? WHERE id = ?');
        $stmt->execute([!empty($b['verified']) ? 1 : 0, $b['id']]);
        echo json_encode(['ok' => true]);
    }

    /** POST /api/admin/notifications/remove */
    public static function remove(): void
    {
        if (!self::isAdmin()) return;
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        if (empty($b['id'])) { http_response_code(422); echo json_encode(['error' => 'id required']); return; }
        Database::get()->prepare('DELETE FROM job_notifications WHERE id = ?')->execute([$b['id']]);
        echo json_encode(['ok' => true]);
    }

    /**
     * GET /api/cron/check-notifications?token=CRON_SECRET
     * Best-effort: scans a news RSS feed for TNPSC/govt-exam recruitment keywords
     * and creates UNVERIFIED draft rows for the admin to review. Never auto-publishes
     * application links/vacancy numbers to students.
     */
    public static function checkNews(): void
    {
        if (($_GET['token'] ?? '') !== getenv('CRON_SECRET') || !getenv('CRON_SECRET')) {
            http_response_code(403); echo json_encode(['error' => 'Invalid token']); return;
        }
        $feeds = ['https://www.thehindu.com/news/national/tamil-nadu/feeder/default.rss'];
        $keywords = ['tnpsc', 'recruitment', 'notification', 'vacancies', 'apply online', 'group 4', 'group 2'];
        $db = Database::get();
        $check = $db->prepare('SELECT id FROM job_notifications WHERE official_notification_link = ? LIMIT 1');
        $insert = $db->prepare(
            "INSERT INTO job_notifications (exam_key, title_ta, title_en, official_notification_link,
                status, is_verified, source, notes_en)
             VALUES ('tnpsc_g4', ?, ?, ?, 'upcoming', 0, 'auto_fetch', 'Draft — needs admin verification before publishing')");
        $drafted = 0;
        foreach ($feeds as $url) {
            $ctx = stream_context_create(['http' => ['timeout' => 12,
                'header' => "User-Agent: VetriTNPSC-NotifBot/1.0\r\n"]]);
            $xml = @file_get_contents($url, false, $ctx);
            if (!$xml) continue;
            $parsed = @simplexml_load_string($xml);
            if (!$parsed || !isset($parsed->channel->item)) continue;
            $n = 0;
            foreach ($parsed->channel->item as $item) {
                if ($n++ >= 15) break;
                $title = trim((string)$item->title);
                $link = trim((string)$item->link);
                $lower = mb_strtolower($title);
                $hit = false;
                foreach ($keywords as $k) { if (str_contains($lower, $k)) { $hit = true; break; } }
                if (!$hit || !$link) continue;
                $check->execute([$link]);
                if ($check->fetch()) continue;
                $insert->execute([$title, $title, $link]);
                $drafted++;
            }
        }
        echo json_encode(['ok' => true, 'drafted' => $drafted,
            'note' => 'Drafts require admin verification before students can see them'], JSON_UNESCAPED_UNICODE);
    }
}
