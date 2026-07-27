<?php
namespace App\Controllers;

use App\Config\Database;
use App\Core\JWT;

class AuthController
{
    private static function body(): array
    {
        return json_decode(file_get_contents('php://input'), true) ?: [];
    }

    public static function register(): void
    {
        $b = self::body();
        $name = trim($b['name'] ?? '');
        $mobile = preg_replace('/\D/', '', $b['mobile'] ?? '');
        $password = $b['password'] ?? '';
        if ($name === '' || strlen($mobile) !== 10 || strlen($password) < 6) {
            http_response_code(422);
            echo json_encode(['error' => 'name, valid 10-digit mobile, password(6+) required']);
            return;
        }
        $db = Database::get();
        $exists = $db->prepare('SELECT id FROM users WHERE mobile = ?');
        $exists->execute([$mobile]);
        if ($exists->fetch()) {
            http_response_code(409);
            echo json_encode(['error' => 'Mobile already registered']);
            return;
        }
        $stmt = $db->prepare('INSERT INTO users (name, mobile, password_hash, target_group, lang) VALUES (?,?,?,?,?)');
        $stmt->execute([$name, $mobile, password_hash($password, PASSWORD_DEFAULT),
            $b['target_group'] ?? 'G4', in_array($b['lang'] ?? 'ta', ['ta','en']) ? $b['lang'] : 'ta']);
        $uid = (int)$db->lastInsertId();
        echo json_encode(['token' => JWT::sign(['uid' => $uid]),
            'user' => ['id' => $uid, 'name' => $name, 'mobile' => $mobile]]);
    }

    public static function login(): void
    {
        $b = self::body();
        $mobile = preg_replace('/\D/', '', $b['mobile'] ?? '');
        $stmt = Database::get()->prepare('SELECT * FROM users WHERE mobile = ?');
        $stmt->execute([$mobile]);
        $user = $stmt->fetch();
        if (!$user || !password_verify($b['password'] ?? '', $user['password_hash'])) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid mobile or password']);
            return;
        }
        echo json_encode(['token' => JWT::sign(['uid' => (int)$user['id']]),
            'user' => ['id' => (int)$user['id'], 'name' => $user['name'],
                       'mobile' => $user['mobile'], 'target_group' => $user['target_group'],
                       'lang' => $user['lang']]]);
    }

    public static function me(): void
    {
        $uid = JWT::userIdFromHeader();
        if (!$uid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); return; }
        $stmt = Database::get()->prepare('SELECT id, name, mobile, target_group, lang FROM users WHERE id = ?');
        $stmt->execute([$uid]);
        echo json_encode(['user' => $stmt->fetch()]);
    }
}
