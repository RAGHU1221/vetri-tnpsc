<?php
namespace App\Core;

class Router
{
    private array $routes = [];

    public function add(string $method, string $path, callable $handler): void
    {
        $this->routes[] = [$method, $path, $handler];
    }

    public function dispatch(): void
    {
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); return; }

        $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        $uri = rtrim($uri, '/') ?: '/';
        foreach ($this->routes as [$method, $path, $handler]) {
            if ($_SERVER['REQUEST_METHOD'] !== $method) continue;
            $pattern = '#^' . preg_replace('#\{(\w+)\}#', '(?P<$1>[^/]+)', $path) . '$#';
            if (preg_match($pattern, $uri, $m)) {
                $params = array_filter($m, 'is_string', ARRAY_FILTER_USE_KEY);
                $handler($params);
                return;
            }
        }
        http_response_code(404);
        echo json_encode(['error' => 'Not found', 'path' => $uri]);
    }
}
