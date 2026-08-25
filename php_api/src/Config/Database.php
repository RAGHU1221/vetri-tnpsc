<?php
namespace App\Config;
use PDO;
use PDOException;
use App\Config\Secrets;
class Database
{
    private static ?PDO $pdo = null;
    public static function get(): PDO
    {
        if (self::$pdo === null) {
            $host = getenv('DB_HOST') ?: Secrets::DB_HOST;
            $port = getenv('DB_PORT') ?: Secrets::DB_PORT;
            $db   = getenv('DB_NAME') ?: Secrets::DB_NAME;
            $dsn  = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
            $opts = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ];
            if ((getenv('DB_SSL') ?: (Secrets::DB_SSL ? 'true' : 'false')) === 'true') {
                $opts[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
            }
            $user = getenv('DB_USER') ?: Secrets::DB_USER;
            $pass = getenv('DB_PASS') ?: Secrets::DB_PASS;
            try {
                self::$pdo = new PDO($dsn, $user, $pass, $opts);
                self::$pdo->exec("SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION'");
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode(['error' => 'DB connection failed']);
                exit;
            }
        }
        return self::$pdo;
    }

    public static function nvidiaApiKey(): ?string
    {
        $key = getenv('NVIDIA_API_KEY');
        if ($key !== false && trim($key) !== '') return trim($key);
        $key = trim(Secrets::NVIDIA_API_KEY);
        return ($key !== '' && !str_contains($key, 'PASTE_NEW_')) ? $key : null;
    }
}