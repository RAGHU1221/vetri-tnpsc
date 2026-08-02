<?php
// CLI: php seed_loader.php  (loads questions_seed.json into MySQL)
// Set env vars first (DB_HOST etc), then run locally.
require __DIR__ . '/src/Config/Database.php';

use App\Config\Database;

$data = json_decode(file_get_contents(__DIR__ . '/questions_seed.json'), true);
if (!$data) exit("questions_seed.json not found/invalid\n");

$db = Database::get();
$stmt = $db->prepare(
    "INSERT INTO questions (group_exam, subject, unit, question_ta, question_en,
        options_ta, options_en, correct_option, book_name_ta, book_name_en,
        page_no, explanation_ta, explanation_en, years_asked, repeat_count,
        question_format, table_data, assertion_ta, assertion_en, reason_ta, reason_en,
        image_url, source_verified)
     VALUES ('G4',?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
     ON DUPLICATE KEY UPDATE explanation_ta = VALUES(explanation_ta),
        years_asked = VALUES(years_asked), repeat_count = VALUES(repeat_count),
        question_format = VALUES(question_format), table_data = VALUES(table_data),
        source_verified = VALUES(source_verified)");

$n = 0;
foreach ($data['questions'] as $q) {
    $tableData = null;
    if (($q['question_format'] ?? 'simple') === 'match_table') {
        $tableData = json_encode([
            'list1_ta' => $q['table_list1_ta'] ?? [], 'list2_ta' => $q['table_list2_ta'] ?? [],
            'list1_en' => $q['table_list1_en'] ?? [], 'list2_en' => $q['table_list2_en'] ?? [],
        ], JSON_UNESCAPED_UNICODE);
    }
    $stmt->execute([
        $q['subject'], $q['unit'], $q['question_ta'], $q['question_en'],
        json_encode($q['options_ta'], JSON_UNESCAPED_UNICODE),
        json_encode($q['options_en'], JSON_UNESCAPED_UNICODE),
        $q['correct'], $q['book_ta'], $q['book_en'] ?? null, $q['page_no'],
        $q['explanation_ta'], $q['explanation_en'],
        json_encode($q['years_asked'] ?? []), $q['repeat_count'] ?? 0,
        $q['question_format'] ?? 'simple', $tableData,
        $q['assertion_ta'] ?? null, $q['assertion_en'] ?? null,
        $q['reason_ta'] ?? null, $q['reason_en'] ?? null,
        $q['image_url'] ?? null, $q['source_verified'] ?? 0,
    ]);
    $n++;
}
echo "Seeded $n questions (including format-rich + source-verified)\n";
