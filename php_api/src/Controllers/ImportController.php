<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class ImportController
{
    private static function requireAdmin(): ?int
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return null; }
        $stmt = Database::get()->prepare('SELECT is_admin FROM users WHERE id = ?');
        $stmt->execute([$uid]);
        if (!($stmt->fetch()['is_admin'] ?? 0)) {
            http_response_code(403); echo json_encode(['error' => 'Admin only']); return null;
        }
        return $uid;
    }

    /** POST /api/admin/import/chunk — {rows:[{...template columns...}]} */
    public static function chunk(): void
    {
        if (self::requireAdmin() === null) return;
        $body = json_decode(file_get_contents('php://input'), true) ?: [];
        $rows = $body['rows'] ?? [];
        if (!$rows || count($rows) > 100) {
            http_response_code(422);
            echo json_encode(['error' => '1-100 rows per chunk required']);
            return;
        }

        $db = Database::get();
        $stmt = $db->prepare(
            "INSERT INTO questions (group_exam, subject, unit, question_ta, question_en,
                options_ta, options_en, correct_option, book_name_ta, book_name_en,
                page_no, explanation_ta, explanation_en, years_asked, repeat_count, difficulty,
                question_format, table_data, assertion_ta, assertion_en, reason_ta, reason_en,
                image_url, source_verified)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
             ON DUPLICATE KEY UPDATE
                question_en = VALUES(question_en), options_ta = VALUES(options_ta),
                options_en = VALUES(options_en), correct_option = VALUES(correct_option),
                book_name_ta = VALUES(book_name_ta), book_name_en = VALUES(book_name_en),
                page_no = VALUES(page_no), explanation_ta = VALUES(explanation_ta),
                explanation_en = VALUES(explanation_en), years_asked = VALUES(years_asked),
                repeat_count = VALUES(repeat_count), difficulty = VALUES(difficulty),
                question_format = VALUES(question_format), table_data = VALUES(table_data),
                assertion_ta = VALUES(assertion_ta), assertion_en = VALUES(assertion_en),
                reason_ta = VALUES(reason_ta), reason_en = VALUES(reason_en),
                image_url = VALUES(image_url), source_verified = VALUES(source_verified)");

        $inserted = $updated = $skipped = 0;
        $errors = [];
        foreach ($rows as $i => $r) {
            $qta = trim($r['question_ta'] ?? '');
            $co = strtoupper(trim($r['correct_option'] ?? ''));
            if ($qta === '' || !in_array($co, ['A','B','C','D'])) {
                $skipped++;
                $errors[] = "Row " . ($r['_row'] ?? $i) . ": question_ta / correct_option (A-D) missing";
                continue;
            }
            $optsTa = [$r['option_a_ta'] ?? '', $r['option_b_ta'] ?? '', $r['option_c_ta'] ?? '', $r['option_d_ta'] ?? ''];
            $optsEn = [$r['option_a_en'] ?? '', $r['option_b_en'] ?? '', $r['option_c_en'] ?? '', $r['option_d_en'] ?? ''];
            if (in_array('', array_map('trim', $optsTa))) {
                $skipped++;
                $errors[] = "Row " . ($r['_row'] ?? $i) . ": 4 Tamil options required";
                continue;
            }
            $years = array_values(array_filter(array_map('trim', explode(',', $r['years_asked'] ?? ''))));
            $diff = in_array($r['difficulty'] ?? '', ['easy','med','hard']) ? $r['difficulty'] : 'med';
            $format = in_array($r['question_format'] ?? '', ['simple','match_table','assertion_reason'])
                ? $r['question_format'] : 'simple';
            $tableData = null;
            if ($format === 'match_table' && !empty($r['table_data'])) {
                $decoded = json_decode($r['table_data'], true);
                $tableData = $decoded ? json_encode($decoded, JSON_UNESCAPED_UNICODE) : null;
            }
            try {
                $stmt->execute([
                    $r['group_exam'] ?: 'G4', trim($r['subject'] ?? 'general'), trim($r['unit'] ?? ''),
                    $qta, trim($r['question_en'] ?? ''),
                    json_encode($optsTa, JSON_UNESCAPED_UNICODE),
                    json_encode($optsEn, JSON_UNESCAPED_UNICODE),
                    ord($co) - 65,
                    trim($r['book_name_ta'] ?? ''), trim($r['book_name_en'] ?? ''),
                    is_numeric($r['page_no'] ?? null) ? (int)$r['page_no'] : null,
                    trim($r['explanation_ta'] ?? ''), trim($r['explanation_en'] ?? ''),
                    json_encode($years), count($years), $diff,
                    $format, $tableData,
                    trim($r['assertion_ta'] ?? '') ?: null, trim($r['assertion_en'] ?? '') ?: null,
                    trim($r['reason_ta'] ?? '') ?: null, trim($r['reason_en'] ?? '') ?: null,
                    trim($r['image_url'] ?? '') ?: null,
                    !empty($r['source_verified']) ? 1 : 0,
                ]);
                // rowCount: 1 = insert, 2 = update (MySQL upsert behaviour)
                $stmt->rowCount() === 1 ? $inserted++ : $updated++;
            } catch (\Throwable $e) {
                $skipped++;
                $errors[] = "Row " . ($r['_row'] ?? $i) . ": DB error";
            }
        }
        echo json_encode(compact('inserted', 'updated', 'skipped', 'errors'));
    }

    /** POST /api/admin/import/log — save final import summary */
    public static function log(): void
    {
        $uid = self::requireAdmin();
        if ($uid === null) return;
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        $stmt = Database::get()->prepare(
            'INSERT INTO import_logs (admin_id, filename, total_rows, inserted_rows, updated_rows, skipped_rows, error_report)
             VALUES (?,?,?,?,?,?,?)');
        $stmt->execute([$uid, $b['filename'] ?? '', (int)($b['total'] ?? 0),
            (int)($b['inserted'] ?? 0), (int)($b['updated'] ?? 0), (int)($b['skipped'] ?? 0),
            json_encode(array_slice($b['errors'] ?? [], 0, 200), JSON_UNESCAPED_UNICODE)]);
        echo json_encode(['ok' => true, 'log_id' => Database::get()->lastInsertId()]);
    }

    /** GET /api/admin/stats — dashboard counts */
    public static function stats(): void
    {
        if (self::requireAdmin() === null) return;
        $db = Database::get();
        $bySubject = $db->query(
            "SELECT subject, COUNT(*) AS total, SUM(repeat_count >= 2) AS important
             FROM questions WHERE is_active = 1 GROUP BY subject")->fetchAll();
        $totals = $db->query(
            "SELECT COUNT(*) AS questions,
                    (SELECT COUNT(*) FROM users) AS users,
                    (SELECT COUNT(*) FROM import_logs) AS imports
             FROM questions WHERE is_active = 1")->fetch();
        $recent = $db->query(
            "SELECT filename, total_rows, inserted_rows, updated_rows, skipped_rows, created_at
             FROM import_logs ORDER BY id DESC LIMIT 5")->fetchAll();
        echo json_encode(['totals' => $totals, 'by_subject' => $bySubject,
            'recent_imports' => $recent], JSON_UNESCAPED_UNICODE);
    }
}
