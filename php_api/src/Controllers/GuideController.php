<?php
namespace App\Controllers;

use App\Config\Database;

class GuideController
{
    /** GET /api/guides?category=govt_job|competitive|school — list (no auth, public reference info) */
    public static function list(): void
    {
        $where = ['is_active = 1'];
        $args = [];
        if (!empty($_GET['category']) && in_array($_GET['category'], ['govt_job','competitive','school','after_12th'])) {
            $where[] = 'category = ?';
            $args[] = $_GET['category'];
        }
        $stmt = Database::get()->prepare(
            "SELECT id, exam_key, category, icon, color_hex, name_ta, name_en,
                    conducting_body_ta, conducting_body_en, age_limit_ta, age_limit_en,
                    salary_ta, salary_en, official_website
             FROM exam_guides WHERE " . implode(' AND ', $where) .
            " ORDER BY display_order, id");
        $stmt->execute($args);
        echo json_encode(['guides' => $stmt->fetchAll()], JSON_UNESCAPED_UNICODE);
    }

    /** GET /api/guides/{exam_key} — full detail */
    public static function detail(array $params): void
    {
        $stmt = Database::get()->prepare('SELECT * FROM exam_guides WHERE exam_key = ? AND is_active = 1');
        $stmt->execute([$params['key']]);
        $g = $stmt->fetch();
        if (!$g) { http_response_code(404); echo json_encode(['error' => 'Guide not found']); return; }
        // convert newline-separated syllabus into arrays for easy UI rendering
        $g['syllabus_ta_list'] = array_values(array_filter(explode("\n", $g['syllabus_ta'] ?? '')));
        $g['syllabus_en_list'] = array_values(array_filter(explode("\n", $g['syllabus_en'] ?? '')));
        $g['exam_pattern_ta_list'] = array_values(array_filter(explode("\n", $g['exam_pattern_ta'] ?? '')));
        $g['exam_pattern_en_list'] = array_values(array_filter(explode("\n", $g['exam_pattern_en'] ?? '')));
        echo json_encode(['guide' => $g], JSON_UNESCAPED_UNICODE);
    }

    /** POST /api/admin/guides — admin add/update (upsert by exam_key) */
    public static function upsert(): void
    {
        $uid = \App\Core\JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $chk = Database::get()->prepare('SELECT is_admin FROM users WHERE id = ?');
        $chk->execute([$uid]);
        if (!($chk->fetch()['is_admin'] ?? 0)) {
            http_response_code(403); echo json_encode(['error' => 'Admin only']); return;
        }
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        if (empty($b['exam_key']) || empty($b['name_ta'])) {
            http_response_code(422); echo json_encode(['error' => 'exam_key & name_ta required']); return;
        }
        $stmt = Database::get()->prepare(
            "INSERT INTO exam_guides (exam_key, category, icon, color_hex, name_ta, name_en,
                conducting_body_ta, conducting_body_en, eligibility_ta, eligibility_en,
                age_limit_ta, age_limit_en, exam_pattern_ta, exam_pattern_en,
                syllabus_ta, syllabus_en, selection_process_ta, selection_process_en,
                salary_ta, salary_en, official_website, prep_tips_ta, prep_tips_en, display_order)
             VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
             ON DUPLICATE KEY UPDATE
                category=VALUES(category), icon=VALUES(icon), color_hex=VALUES(color_hex),
                name_ta=VALUES(name_ta), name_en=VALUES(name_en),
                conducting_body_ta=VALUES(conducting_body_ta), conducting_body_en=VALUES(conducting_body_en),
                eligibility_ta=VALUES(eligibility_ta), eligibility_en=VALUES(eligibility_en),
                age_limit_ta=VALUES(age_limit_ta), age_limit_en=VALUES(age_limit_en),
                exam_pattern_ta=VALUES(exam_pattern_ta), exam_pattern_en=VALUES(exam_pattern_en),
                syllabus_ta=VALUES(syllabus_ta), syllabus_en=VALUES(syllabus_en),
                selection_process_ta=VALUES(selection_process_ta), selection_process_en=VALUES(selection_process_en),
                salary_ta=VALUES(salary_ta), salary_en=VALUES(salary_en),
                official_website=VALUES(official_website),
                prep_tips_ta=VALUES(prep_tips_ta), prep_tips_en=VALUES(prep_tips_en),
                display_order=VALUES(display_order)");
        $stmt->execute([
            $b['exam_key'], $b['category'] ?? 'govt_job', $b['icon'] ?? '📋', $b['color_hex'] ?? '#2E7D4F',
            $b['name_ta'], $b['name_en'] ?? '', $b['conducting_body_ta'] ?? '', $b['conducting_body_en'] ?? '',
            $b['eligibility_ta'] ?? '', $b['eligibility_en'] ?? '', $b['age_limit_ta'] ?? '', $b['age_limit_en'] ?? '',
            $b['exam_pattern_ta'] ?? '', $b['exam_pattern_en'] ?? '', $b['syllabus_ta'] ?? '', $b['syllabus_en'] ?? '',
            $b['selection_process_ta'] ?? '', $b['selection_process_en'] ?? '', $b['salary_ta'] ?? '', $b['salary_en'] ?? '',
            $b['official_website'] ?? '', $b['prep_tips_ta'] ?? '', $b['prep_tips_en'] ?? '', (int)($b['display_order'] ?? 0),
        ]);
        echo json_encode(['ok' => true]);
    }
}
