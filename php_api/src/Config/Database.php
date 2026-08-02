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
            $host = getenv('DB_HOST');
            $port = getenv('DB_PORT') ?: '3306';
            $db   = getenv('DB_NAME');
            $dsn  = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
            $opts = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ];
            if (getenv('DB_SSL') === 'true') {
                $opts[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
            }
            try {
                self::$pdo = new PDO($dsn, getenv('DB_USER'), getenv('DB_PASS'), $opts);
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
