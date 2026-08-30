import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/syllabus_screen.dart';
import 'ui/screens/question_list_screen.dart';
import 'ui/screens/test_setup_screen.dart';
import 'ui/screens/test_screen.dart';
import 'ui/screens/test_result_screen.dart';
import 'ui/screens/ca_screen.dart';
import 'ui/screens/ai_chat_screen.dart';
import 'ui/screens/progress_screen.dart';
import 'ui/screens/guide_list_screen.dart';
import 'ui/screens/guide_detail_screen.dart';
import 'ui/screens/cutoff_calculator_screen.dart';
import 'ui/screens/notifications_screen.dart';
import 'ui/screens/lesson_list_screen.dart';
import 'ui/screens/lesson_detail_screen.dart';
import 'ui/screens/lesson_test_screen.dart';
import 'services/test_service.dart';
import 'services/question_service.dart';
import 'services/lesson_service.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    // Never let an auth-check failure (storage/plugin error) block routing —
    // fall back to "not logged in" so the app always reaches a usable screen.
    bool loggedIn = false;
    try {
      loggedIn = await AuthService().isLoggedIn();
    } catch (_) {
      loggedIn = false;
    }
    final onAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
    if (!loggedIn && !onAuth) return '/login';
    if (loggedIn && onAuth) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
    GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
    GoRoute(path: '/syllabus', builder: (c, s) => const SyllabusScreen()),
    GoRoute(
      path: '/questions/:subject',
      builder: (c, s) => QuestionListScreen(subject: s.pathParameters['subject']!),
    ),
    GoRoute(path: '/test-setup', builder: (c, s) => const TestSetupScreen()),
    GoRoute(path: '/current-affairs', builder: (c, s) => const CAScreen()),
    GoRoute(
      path: '/ai-chat',
      builder: (c, s) => AIChatScreen(initialQuestion: s.extra as String?),
    ),
    GoRoute(path: '/progress', builder: (c, s) => const ProgressScreen()),
    GoRoute(path: '/guide', builder: (c, s) => const GuideListScreen()),
    GoRoute(
      path: '/guide/:key',
      builder: (c, s) => GuideDetailScreen(examKey: s.pathParameters['key']!),
    ),
    GoRoute(path: '/cutoff-calculator', builder: (c, s) => const CutoffCalculatorScreen()),
    GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
    GoRoute(path: '/lessons', builder: (c, s) => const LessonListScreen()),
    GoRoute(
      path: '/lessons/:id',
      builder: (c, s) {
        final id = int.parse(s.pathParameters['id']!);
        // key: without this, Flutter can reuse the SAME State object when
        // navigating from one lesson to another (both are the same widget
        // type at the same tree position) — its initState() (which kicks
        // off the fetch) never re-runs, so the OLD lesson's data stays on
        // screen even though the id in the URL changed. The key forces a
        // brand-new widget/State per lesson id.
        return LessonDetailScreen(key: ValueKey('lesson-$id'), lessonId: id);
      },
    ),
    GoRoute(
      path: '/lessons/:id/test',
      builder: (c, s) => LessonTestScreen(lesson: s.extra as LessonDetail),
    ),
    GoRoute(
      path: '/test',
      builder: (c, s) => TestScreen(config: s.extra as TestConfig),
    ),
    GoRoute(
      path: '/test-result',
      builder: (c, s) {
        final (result, questions, answers, auto) =
            s.extra as (TestResult, List<Question>, Map<int, int>, bool);
        return TestResultScreen(
            result: result, questions: questions,
            answers: answers, autoSubmitted: auto);
      },
    ),
  ],
);
