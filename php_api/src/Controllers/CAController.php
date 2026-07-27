<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class CAController
{
    /** GET /api/current-affairs?month=2026-07&tn=1&category=&limit= */
    public static function list(): void
    {
        $where = ['is_active = 1'];
        $args = [];
        if (!empty($_GET['month']) && preg_match('/^\d{4}-\d{2}$/', $_GET['month'])) {
            $where[] = "DATE_FORMAT(ca_date, '%Y-%m') = ?";
            $args[] = $_GET['month'];
        }
        if (!empty($_GET['tn'])) $where[] = 'is_tn = 1';
        if (!empty($_GET['category'])) { $where[] = 'category = ?'; $args[] = $_GET['category']; }
        $limit = min(200, max(1, (int)($_GET['limit'] ?? 100)));
        $stmt = Database::get()->prepare(
            'SELECT id, ca_date, category, title_ta, title_en, content_ta, content_en, is_tn, source_url
             FROM current_affairs WHERE ' . implode(' AND ', $where) .
            " ORDER BY ca_date DESC, is_tn DESC, id DESC LIMIT $limit");
        $stmt->execute($args);
        echo json_encode(['items' => $stmt->fetchAll()], JSON_UNESCAPED_UNICODE);
    }

    /** GET /api/daily-quiz — date-seeded 10 questions (same set for all users that day) */
    public static function dailyQuiz(): void
    {
        if (!JWT::userIdFromHeader()) {
            http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return;
        }
        $db = Database::get();
        $count = (int)$db->query('SELECT COUNT(*) c FROM questions WHERE is_active = 1')->fetch()['c'];
        if ($count === 0) { echo json_encode(['questions' => []]); return; }
        // Deterministic daily selection: seed = date
        $seed = (int)date('Ymd');
        $stmt = $db->query(
            "SELECT id, subject, unit, question_ta, question_en, options_ta, options_en,
                    correct_option, book_name_ta, page_no, explanation_ta, explanation_en,
                    years_asked, repeat_count
             FROM questions WHERE is_active = 1
             ORDER BY RAND($seed) LIMIT 10");
        $out = [];
        foreach ($stmt->fetchAll() as $q) {
            $q['options_ta'] = json_decode($q['options_ta'], true);
            $q['options_en'] = json_decode($q['options_en'] ?? '[]', true);
            $q['years_asked'] = json_decode($q['years_asked'] ?? '[]', true);
            $out[] = $q;
        }
        echo json_encode(['date' => date('Y-m-d'), 'questions' => $out], JSON_UNESCAPED_UNICODE);
    }

    /** POST /api/admin/ca — add CA item (admin) */
    public static function add(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $chk = Database::get()->prepare('SELECT is_admin FROM users WHERE id = ?');
        $chk->execute([$uid]);
        if (!($chk->fetch()['is_admin'] ?? 0)) {
            http_response_code(403); echo json_encode(['error' => 'Admin only']); return;
        }
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        if (empty($b['title_ta']) || empty($b['ca_date'])) {
            http_response_code(422);
            echo json_encode(['error' => 'title_ta & ca_date required']);
            return;
        }
        $stmt = Database::get()->prepare(
            'INSERT INTO current_affairs (ca_date, category, title_ta, title_en, content_ta, content_en, is_tn, source_url)
             VALUES (?,?,?,?,?,?,?,?)');
        $stmt->execute([$b['ca_date'], $b['category'] ?? 'general',
            trim($b['title_ta']), trim($b['title_en'] ?? ''),
            trim($b['content_ta'] ?? ''), trim($b['content_en'] ?? ''),
            !empty($b['is_tn']) ? 1 : 0, trim($b['source_url'] ?? '')]);
        echo json_encode(['ok' => true, 'id' => Database::get()->lastInsertId()]);
    }
}
