<?php
// வெற்றி TNPSC API — Phase 1
spl_autoload_register(function ($class) {
    $path = __DIR__ . '/../' . str_replace(['App\\', '\\'], ['src/', '/'], $class) . '.php';
    if (file_exists($path)) require $path;
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
