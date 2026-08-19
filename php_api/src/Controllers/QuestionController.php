<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class QuestionController
{
    /** GET /api/subjects?group_exam=G4|G2A — syllabus tree derived from questions */
    public static function subjects(): void
    {
        $group = in_array($_GET['group_exam'] ?? '', ['G4', 'G2A', 'G1', 'G2', 'NMMS']) ? $_GET['group_exam'] : 'G4';
        $stmt = Database::get()->prepare(
            "SELECT subject, unit, COUNT(*) AS q_count,
                    SUM(repeat_count >= 2) AS important_count
             FROM questions WHERE is_active = 1 AND group_exam = ?
             GROUP BY subject, unit ORDER BY subject, unit");
        $stmt->execute([$group]);
        $rows = $stmt->fetchAll();
        $tree = [];
        foreach ($rows as $r) {
            $tree[$r['subject']]['subject'] = $r['subject'];
            $tree[$r['subject']]['total'] = ($tree[$r['subject']]['total'] ?? 0) + (int)$r['q_count'];
            $tree[$r['subject']]['units'][] = [
                'unit' => $r['unit'],
                'count' => (int)$r['q_count'],
                'important' => (int)$r['important_count'],
            ];
        }
        echo json_encode(['subjects' => array_values($tree)], JSON_UNESCAPED_UNICODE);
    }

    /** GET /api/questions?subject=&unit=&important=1&limit=&offset= */
    public static function list(): void
    {
        if (!JWT::userIdFromHeader()) {
            http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return;
        }
        $where = ['is_active = 1'];
        $args = [];
        // group_exam filter is optional here: the app fetches all groups once and
        // filters client-side (see QuestionService.bySubject/buildTest), so the
        // offline cache always has every group available for instant switching.
        if (in_array($_GET['group_exam'] ?? '', ['G4', 'G2A', 'G1', 'G2', 'NMMS'])) {
            $where[] = 'group_exam = ?'; $args[] = $_GET['group_exam'];
        }
        if (!empty($_GET['subject'])) { $where[] = 'subject = ?'; $args[] = $_GET['subject']; }
        if (!empty($_GET['unit']))    { $where[] = 'unit = ?';    $args[] = $_GET['unit']; }
        if (!empty($_GET['important'])) { $where[] = 'repeat_count >= 2'; }
        $limit = min(500, max(1, (int)($_GET['limit'] ?? 50)));
        $offset = max(0, (int)($_GET['offset'] ?? 0));
        $sql = 'SELECT id, group_exam, subject, unit, question_ta, question_en,
                       question_format, table_data, assertion_ta, assertion_en, reason_ta, reason_en,
                       image_url, source_verified,
                       options_ta, options_en, correct_option, book_name_ta, book_name_en,
                       page_no, explanation_ta, explanation_en, years_asked, repeat_count, difficulty
                FROM questions WHERE ' . implode(' AND ', $where) .
               " ORDER BY repeat_count DESC, id LIMIT $limit OFFSET $offset";
        $stmt = Database::get()->prepare($sql);
        $stmt->execute($args);
        $out = [];
        foreach ($stmt->fetchAll() as $q) {
            $q['options_ta'] = json_decode($q['options_ta'], true);
            $q['options_en'] = json_decode($q['options_en'] ?? '[]', true);
            $q['years_asked'] = json_decode($q['years_asked'] ?? '[]', true);
            $q['table_data'] = $q['table_data'] ? json_decode($q['table_data'], true) : null;
            $out[] = $q;
        }
        echo json_encode(['questions' => $out, 'count' => count($out)], JSON_UNESCAPED_UNICODE);
    }
}
