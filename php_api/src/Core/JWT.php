<?php
namespace App\Core;

class JWT
{
    private static function b64(string $d): string
    {
        return rtrim(strtr(base64_encode($d), '+/', '-_'), '=');
    }

    public static function sign(array $payload, int $ttl = 2592000): string
    {
        $header = self::b64(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $payload['exp'] = time() + $ttl;
        $body = self::b64(json_encode($payload));
        $sig = self::b64(hash_hmac('sha256', "$header.$body", getenv('JWT_SECRET'), true));
        return "$header.$body.$sig";
    }

    public static function verify(?string $token): ?array
    {
        if (!$token || substr_count($token, '.') !== 2) return null;
        [$h, $b, $s] = explode('.', $token);
        $expected = rtrim(strtr(base64_encode(
            hash_hmac('sha256', "$h.$b", getenv('JWT_SECRET'), true)), '+/', '-_'), '=');
        if (!hash_equals($expected, $s)) return null;
        $payload = json_decode(base64_decode(strtr($b, '-_', '+/')), true);
        if (!$payload || ($payload['exp'] ?? 0) < time()) return null;
        return $payload;
    }

    public static function userIdFromHeader(): ?int
    {
        $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/Bearer\s+(.+)/', $auth, $m)) return null;
        $p = self::verify($m[1]);
        return $p['uid'] ?? null;
    }
}
