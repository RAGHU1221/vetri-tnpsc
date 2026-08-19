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
import 'services/test_service.dart';
import 'services/question_service.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await AuthService().isLoggedIn();
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
