<?php
namespace App\Config;

use PDO;
use PDOException;

class Database
{
    private static ?PDO $pdo = null;

    public static function get(): PDO
    {
        if (self::$pdo === null) {
            // getenv() fallback defaults - AIC Cloud shared hosting-la (Render/Docker illama)
            // .env / container env vars set panna mudiyathu poidhu, so idhu fallback:
            $host = getenv('DB_HOST') ?: 'localhost';
            $port = getenv('DB_PORT') ?: '3306';
            $db   = getenv('DB_NAME') ?: 'aicazxokw_vetri_tnpsc';
            $dsn  = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
            $opts = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ];
            if (getenv('DB_SSL') === 'true') {
                $opts[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
            }
            $user = getenv('DB_USER') ?: 'aicazxokw_vetri_user';
            $pass = getenv('DB_PASS') ?: 'Prithika@1221';
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
}
