<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class TestController
{
    /** POST /api/tests/submit — {test_type, subject, total, correct, wrong, skipped, time_taken_sec, weak_subjects} */
    public static function submit(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $b = json_decode(file_get_contents('php://input'), true) ?: [];
        $total = max(1, (int)($b['total'] ?? 0));
        $correct = max(0, (int)($b['correct'] ?? 0));
        $score = round($correct * 1.5, 2); // TNPSC G4: 300 marks / 200 Q = 1.5 per Q

        $db = Database::get();
        $stmt = $db->prepare(
            'INSERT INTO test_results (user_id, test_type, subject, total_questions,
                correct, wrong, skipped, score, time_taken_sec, weak_subjects)
             VALUES (?,?,?,?,?,?,?,?,?,?)');
        $stmt->execute([$uid,
            in_array($b['test_type'] ?? '', ['mini','full','daily']) ? $b['test_type'] : 'mini',
            $b['subject'] ?: null, $total, $correct,
            max(0, (int)($b['wrong'] ?? 0)), max(0, (int)($b['skipped'] ?? 0)),
            $score, max(0, (int)($b['time_taken_sec'] ?? 0)),
            json_encode($b['weak_subjects'] ?? [], JSON_UNESCAPED_UNICODE)]);

        // Percentile: same test_type-la ivarai vida kammi score percent
        $pct = $db->prepare(
            'SELECT ROUND(100 * SUM(score < ?) / GREATEST(COUNT(*), 1), 1) AS percentile
             FROM test_results WHERE test_type = ?');
        $pct->execute([$score, $b['test_type'] ?? 'mini']);
        $percentile = (float)($pct->fetch()['percentile'] ?? 0);

        echo json_encode(['ok' => true, 'score' => $score,
            'accuracy' => round($correct / $total * 100, 1),
            'percentile' => $percentile]);
    }

    /** GET /api/tests/history */
    public static function history(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $stmt = Database::get()->prepare(
            'SELECT test_type, subject, total_questions, correct, wrong, skipped,
                    score, time_taken_sec, weak_subjects, created_at
             FROM test_results WHERE user_id = ? ORDER BY id DESC LIMIT 20');
        $stmt->execute([$uid]);
        $rows = $stmt->fetchAll();
        foreach ($rows as &$r) $r['weak_subjects'] = json_decode($r['weak_subjects'] ?? '[]', true);
        echo json_encode(['history' => $rows], JSON_UNESCAPED_UNICODE);
    }
}
