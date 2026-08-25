<?php
// வெற்றி TNPSC API — Phase 1

// Optional .env loader — no Composer/phpdotenv needed. Reads KEY=VALUE lines
// from a real .env file on disk and exposes them through getenv()/putenv(),
// the exact interface Database.php, CronCAController.php etc already use.
// This is a SAFE ADD-ON: it never overwrites a key that already resolves
// via getenv() (e.g. DB_HOST already working through the hosting panel) —
// it only fills in keys that are currently missing (CRON_SECRET,
// NVIDIA_API_KEY). Looks in both the same folder as this file and one
// level up, so it works whichever way this app was deployed on the server.
foreach ([__DIR__ . '/.env', __DIR__ . '/../.env'] as $envFile) {
    if (!is_file($envFile)) continue;
    foreach (file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$k, $v] = explode('=', $line, 2);
        $k = trim($k);
        $v = trim($v, " \t\n\r\0\x0B\"'");
        if ($k !== '' && getenv($k) === false) {
            putenv("$k=$v");
            $_ENV[$k] = $v;
        }
    }
    break; // first .env file found wins
}

// Autoloader — tries index.php's OWN folder first (src/ as a direct
// sibling of index.php), then one level up (src/ as a sibling of the
// folder that contains index.php). This makes class loading work no
// matter which of the two ever gets used on this hosting panel, instead
// of hard-assuming one fixed layout — a layout mismatch here previously
// caused "Class not found" fatal errors on EVERY route (including
// login), since Router itself failed to autoload.
spl_autoload_register(function ($class) {
    $rel = str_replace(['App\\', '\\'], ['src/', '/'], $class) . '.php';
    foreach ([__DIR__ . '/' . $rel, __DIR__ . '/../' . $rel] as $path) {
        if (file_exists($path)) { require $path; return; }
    }
});

use App\Core\Router;
use App\Controllers\AuthController;
use App\Controllers\QuestionController;
use App\Controllers\ImportController;
use App\Controllers\TestController;
use App\Controllers\CAController;
use App\Controllers\AIController;
use App\Controllers\StatsController;
use App\Controllers\CronCAController;
use App\Controllers\GuideController;
use App\Controllers\NotificationController;

$r = new Router();
$r->add('GET',  '/',                  fn() => print json_encode(['app' => 'Vetri TNPSC API', 'status' => 'ok']));
$r->add('POST', '/api/auth/register', fn() => AuthController::register());
$r->add('POST', '/api/auth/login',    fn() => AuthController::login());
$r->add('GET',  '/api/auth/me',       fn() => AuthController::me());
$r->add('GET',  '/api/subjects',      fn() => QuestionController::subjects());
$r->add('GET',  '/api/questions',     fn() => QuestionController::list());
// Phase 2: admin import
$r->add('POST', '/api/admin/import/chunk', fn() => ImportController::chunk());
$r->add('POST', '/api/admin/import/log',   fn() => ImportController::log());
$r->add('GET',  '/api/admin/stats',        fn() => ImportController::stats());
// Phase 3: mock tests
$r->add('POST', '/api/tests/submit',  fn() => TestController::submit());
$r->add('GET',  '/api/tests/history', fn() => TestController::history());
// Phase 4: current affairs
$r->add('GET',  '/api/current-affairs', fn() => CAController::list());
$r->add('GET',  '/api/daily-quiz',      fn() => CAController::dailyQuiz());
$r->add('POST', '/api/admin/ca',        fn() => CAController::add());
// Phase 5: AI tutor
$r->add('POST', '/api/ai/chat',    fn() => AIController::chat());
$r->add('POST', '/api/ai/explain', fn() => AIController::explain());
// Phase 6: growth
$r->add('POST', '/api/streak/ping',  fn() => StatsController::streakPing());
$r->add('GET',  '/api/leaderboard',  fn() => StatsController::leaderboard());
$r->add('GET',  '/api/progress',     fn() => StatsController::progress());
// Cron: daily current-affairs auto-fetch
$r->add('GET',  '/api/cron/fetch-ca', fn() => CronCAController::fetchDaily());
// வழிகாட்டி (exam guide directory)
$r->add('GET',  '/api/guides',       fn() => GuideController::list());
$r->add('GET',  '/api/guides/{key}',  fn($p) => GuideController::detail($p));
$r->add('POST', '/api/admin/guides',  fn() => GuideController::upsert());
// அறிவிப்புகள் (job notifications)
$r->add('GET',  '/api/notifications',              fn() => NotificationController::list());
$r->add('GET',  '/api/admin/notifications',        fn() => NotificationController::adminList());
$r->add('POST', '/api/admin/notifications/upsert', fn() => NotificationController::upsert());
$r->add('POST', '/api/admin/notifications/verify', fn() => NotificationController::verify());
$r->add('POST', '/api/admin/notifications/remove', fn() => NotificationController::remove());
$r->add('GET',  '/api/cron/check-notifications',   fn() => NotificationController::checkNews());
$r->dispatch();