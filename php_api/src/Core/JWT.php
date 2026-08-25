<?php
namespace App\Core;

use App\Config\Secrets;
class JWT
{
    // Same hardcoded-fallback pattern as Database.php — this hosting panel
    // doesn't reliably expose custom env vars (no .env in use here), so
    // getenv('JWT_SECRET') was returning empty/false inconsistently between
    // requests, meaning sign() and verify() sometimes used different keys.
    private static function secret(): string
    {
        return getenv('JWT_SECRET') ?: Secrets::JWT_SECRET;
    }

    private static function b64(string $d): string
    {
        return rtrim(strtr(base64_encode($d), '+/', '-_'), '=');
    }
    public static function sign(array $payload, int $ttl = 2592000): string
    {
        $header = self::b64(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $payload['exp'] = time() + $ttl;
        $body = self::b64(json_encode($payload));
        $sig = self::b64(hash_hmac('sha256', "$header.$body", self::secret(), true));
        return "$header.$body.$sig";
    }
    public static function verify(?string $token): ?array
    {
        if (!$token || substr_count($token, '.') !== 2) return null;
        [$h, $b, $s] = explode('.', $token);
        $expected = rtrim(strtr(base64_encode(
            hash_hmac('sha256', "$h.$b", self::secret(), true)), '+/', '-_'), '=');
        if (!hash_equals($expected, $s)) return null;
        $payload = json_decode(base64_decode(strtr($b, '-_', '+/')), true);
        if (!$payload || ($payload['exp'] ?? 0) < time()) return null;
        return $payload;
    }

    /**
     * Reads the raw Authorization header value, trying every location PHP
     * might put it depending on server config:
     *  - $_SERVER['HTTP_AUTHORIZATION']            — normal case
     *  - $_SERVER['REDIRECT_HTTP_AUTHORIZATION']   — Apache mod_rewrite often
     *    renames it to this when the request is internally redirected to
     *    index.php (exactly what this app's routing does) — THIS was the
     *    actual bug: the token was being sent correctly by the browser and
     *    signed/verified correctly by JWT itself, but PHP could never see
     *    it because only the plain HTTP_ key was checked.
     *  - apache_request_headers() / getallheaders() — final fallback for
     *    servers that strip it from $_SERVER entirely (case-insensitive
     *    lookup, since header casing varies by server/proxy).
     */
    private static function rawAuthHeader(): string
    {
        foreach (['HTTP_AUTHORIZATION', 'REDIRECT_HTTP_AUTHORIZATION'] as $key) {
            if (!empty($_SERVER[$key])) return $_SERVER[$key];
        }
        if (function_exists('apache_request_headers')) {
            foreach (apache_request_headers() as $k => $v) {
                if (strcasecmp($k, 'Authorization') === 0) return $v;
            }
        }
        if (function_exists('getallheaders')) {
            foreach (getallheaders() as $k => $v) {
                if (strcasecmp($k, 'Authorization') === 0) return $v;
            }
        }
        return '';
    }

    public static function userIdFromHeader(): ?int
    {
        $auth = self::rawAuthHeader();
        if (!preg_match('/Bearer\s+(.+)/', $auth, $m)) return null;
        $p = self::verify(trim($m[1]));
        return $p['uid'] ?? null;
    }
}