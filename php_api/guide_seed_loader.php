<?php
// CLI: php guide_seed_loader.php  (loads exam_guides_seed.json into MySQL)
require __DIR__ . '/src/Config/Database.php';
use App\Config\Database;

$data = json_decode(file_get_contents(__DIR__ . '/exam_guides_seed.json'), true);
if (!$data) exit("exam_guides_seed.json not found/invalid\n");

$db = Database::get();
$stmt = $db->prepare(
    "INSERT INTO exam_guides (exam_key, category, icon, color_hex, name_ta, name_en,
        conducting_body_ta, conducting_body_en, eligibility_ta, eligibility_en,
        age_limit_ta, age_limit_en, exam_pattern_ta, exam_pattern_en,
        syllabus_ta, syllabus_en, selection_process_ta, selection_process_en,
        salary_ta, salary_en, official_website, prep_tips_ta, prep_tips_en, display_order)
     VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
     ON DUPLICATE KEY UPDATE
        eligibility_ta=VALUES(eligibility_ta), age_limit_ta=VALUES(age_limit_ta),
        exam_pattern_ta=VALUES(exam_pattern_ta), syllabus_ta=VALUES(syllabus_ta),
        prep_tips_ta=VALUES(prep_tips_ta), display_order=VALUES(display_order)");

$n = 0;
foreach ($data as $g) {
    $stmt->execute([
        $g['exam_key'], $g['category'], $g['icon'], $g['color_hex'], $g['name_ta'], $g['name_en'],
        $g['conducting_body_ta'], $g['conducting_body_en'], $g['eligibility_ta'], $g['eligibility_en'],
        $g['age_limit_ta'], $g['age_limit_en'], $g['exam_pattern_ta'], $g['exam_pattern_en'],
        $g['syllabus_ta'], $g['syllabus_en'], $g['selection_process_ta'], $g['selection_process_en'],
        $g['salary_ta'], $g['salary_en'], $g['official_website'], $g['prep_tips_ta'], $g['prep_tips_en'],
        $g['display_order'],
    ]);
    $n++;
}
echo "Seeded $n exam guides\n";
