<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class StatsController
{
    /** POST /api/streak/ping — app open panna daily streak update */
    public static function streakPing(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $db = Database::get();
        $stmt = $db->prepare('SELECT * FROM user_streaks WHERE user_id = ?');
        $stmt->execute([$uid]);
        $row = $stmt->fetch();
        $today = date('Y-m-d');
        $yesterday = date('Y-m-d', strtotime('-1 day'));

        if (!$row) {
            $db->prepare('INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_active_date)
                          VALUES (?,1,1,?)')->execute([$uid, $today]);
            echo json_encode(['current_streak' => 1, 'longest_streak' => 1]);
            return;
        }
        $current = (int)$row['current_streak'];
        if ($row['last_active_date'] === $today) {
            // already counted today
        } elseif ($row['last_active_date'] === $yesterday) {
            $current += 1; // streak continues 🔥
        } else {
            $current = 1;  // streak broken, restart
        }
        $longest = max($current, (int)$row['longest_streak']);
        $db->prepare('UPDATE user_streaks SET current_streak=?, longest_streak=?, last_active_date=? WHERE user_id=?')
           ->execute([$current, $longest, $today, $uid]);
        echo json_encode(['current_streak' => $current, 'longest_streak' => $longest]);
    }

    /** GET /api/leaderboard?period=week|all — daily quiz & tests based */
    public static function leaderboard(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $db = Database::get();
        $since = ($_GET['period'] ?? 'week') === 'week'
            ? "AND t.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)" : '';
        // Top 20 by total score
        $top = $db->query(
            "SELECT u.id, u.name, ROUND(SUM(t.score),1) AS total_score,
                    COUNT(*) AS tests, ROUND(AVG(t.correct/t.total_questions*100),1) AS accuracy
             FROM test_results t JOIN users u ON u.id = t.user_id
             WHERE 1=1 $since
             GROUP BY u.id, u.name ORDER BY total_score DESC LIMIT 20")->fetchAll();
        $rank = null;
        foreach ($top as $i => &$r) {
            $r['rank'] = $i + 1;
            $r['is_me'] = ((int)$r['id'] === $uid);
            if ($r['is_me']) $rank = $i + 1;
            unset($r['id']); // privacy: id venaam
        }
        echo json_encode(['leaderboard' => $top, 'my_rank' => $rank], JSON_UNESCAPED_UNICODE);
    }

    /** GET /api/progress — personal analytics */
    public static function progress(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $db = Database::get();
        $overall = $db->prepare(
            'SELECT COUNT(*) AS tests, COALESCE(SUM(correct),0) AS correct,
                    COALESCE(SUM(total_questions),0) AS attempted,
                    COALESCE(ROUND(AVG(correct/total_questions*100),1),0) AS avg_accuracy
             FROM test_results WHERE user_id = ?');
        $overall->execute([$uid]);
        $subj = $db->prepare(
            "SELECT subject, COUNT(*) AS tests,
                    ROUND(AVG(correct/total_questions*100),1) AS accuracy
             FROM test_results WHERE user_id = ? AND subject IS NOT NULL
             GROUP BY subject ORDER BY accuracy ASC");
        $subj->execute([$uid]);
        $streak = $db->prepare('SELECT current_streak, longest_streak FROM user_streaks WHERE user_id = ?');
        $streak->execute([$uid]);
        echo json_encode([
            'overall' => $overall->fetch(),
            'by_subject' => $subj->fetchAll(),
            'streak' => $streak->fetch() ?: ['current_streak' => 0, 'longest_streak' => 0],
        ], JSON_UNESCAPED_UNICODE);
    }
}
