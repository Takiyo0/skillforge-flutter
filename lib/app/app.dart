import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_state.dart';
import '../ui/design_system.dart';
import '../utils/permissions.dart';
import '../views/admin/admin_badges_screen.dart';
import '../views/admin/admin_course_detail_screen.dart';
import '../views/admin/admin_courses_screen.dart';
import '../views/admin/admin_home_screen.dart';
import '../views/admin/admin_learning_paths_screen.dart';
import '../views/admin/admin_shell_screen.dart';
import '../views/admin/admin_unit_placeholder_screen.dart';
import '../views/admin/admin_users_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/shared/certificate_screen.dart';
import '../views/shared/certificate_verification_screen.dart';
import '../views/shared/shell_screen.dart';
import '../views/student/assessment_screen.dart';
import '../views/student/browse_courses_screen.dart';
import '../views/student/certificates_screen.dart';
import '../views/student/code_playground_screen.dart';
import '../views/student/course_detail_screen.dart';
import '../views/student/course_forums_screen.dart';
import '../views/student/forum_thread_screen.dart';
import '../views/student/leaderboard_screen.dart';
import '../views/student/learning_path_screen.dart';
import '../views/student/learning_paths_screen.dart';
import '../views/student/more_screen.dart';
import '../views/student/profile_screen.dart';
import '../views/student/settings_screen.dart';
import '../views/student/student_dashboard_screen.dart';
import '../views/student/unit_view_screen.dart';
import '../views/student/user_forums_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authGate = ref.watch(
    sessionProvider.select(
      (s) => (
        isBootstrapping: s.isBootstrapping,
        isAuthenticated: s.isAuthenticated,
        roles: s.user?.roles.join('|') ?? '',
      ),
    ),
  );
  final session = ref.read(sessionProvider);

  return GoRouter(
    initialLocation: '/student/dashboard',
    redirect: (context, state) {
      if (authGate.isBootstrapping) {
        return state.matchedLocation == '/loading' ? null : '/loading';
      }

      if (state.matchedLocation == '/loading') {
        return authGate.isAuthenticated ? '/student/dashboard' : '/login';
      }

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation.startsWith('/certificates/');

      if (!authGate.isAuthenticated && !isAuthRoute) return '/login';
      if (authGate.isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/student/dashboard';
      }
      if (state.matchedLocation.startsWith('/admin') &&
          !canAccessAdmin(session.user)) {
        return '/student/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        pageBuilder: (_, state) => _page(
          state,
          const Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, __) => const NoTransitionPage<void>(
          key: ValueKey('login-page'),
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, __) => const NoTransitionPage<void>(
          key: ValueKey('register-page'),
          child: RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/certificates/verification',
        pageBuilder: (_, state) => _page(
          state,
          CertificateVerificationPage(
            verificationCode: state.uri.queryParameters['code'],
          ),
        ),
      ),
      GoRoute(
        path: '/student/certificates/verification',
        pageBuilder: (_, state) => _page(
          state,
          CertificateVerificationPage(
            verificationCode: state.uri.queryParameters['code'],
          ),
        ),
      ),
      GoRoute(
        path: '/certificates/:certificateId',
        pageBuilder: (_, state) => _page(
          state,
          CertificatePage(
            certificateId: state.pathParameters['certificateId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/student/certificates/:certificateId',
        pageBuilder: (_, state) => _page(
          state,
          CertificatePage(
            certificateId: state.pathParameters['certificateId']!,
          ),
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/student/dashboard',
            pageBuilder: (_, state) =>
                _page(state, const StudentDashboardPage()),
          ),
          GoRoute(
            path: '/student/browse-courses',
            pageBuilder: (_, state) => _page(state, const BrowseCoursesPage()),
          ),
          GoRoute(
            path: '/student/learning-paths',
            pageBuilder: (_, state) => _page(state, const LearningPathsPage()),
          ),
          GoRoute(
            path: '/student/learning-path',
            pageBuilder: (_, state) => _page(state, const LearningPathPage()),
          ),
          GoRoute(
            path: '/student/forum',
            pageBuilder: (_, state) => _page(state, const UserForumsPage()),
          ),
          GoRoute(
            path: '/student/more',
            pageBuilder: (_, state) => _page(state, const MorePage()),
          ),
          GoRoute(
            path: '/student/leaderboard',
            pageBuilder: (_, state) => _page(state, const LeaderboardPage()),
          ),
          GoRoute(
            path: '/student/code-sandbox',
            pageBuilder: (_, state) => _page(state, const CodePlaygroundPage()),
          ),
          GoRoute(
            path: '/student/playground',
            pageBuilder: (_, state) => _page(state, const CodePlaygroundPage()),
          ),
          GoRoute(
            path: '/student/certificates',
            pageBuilder: (_, state) => _page(state, const CertificatesPage()),
          ),
          GoRoute(
            path: '/student/settings',
            pageBuilder: (_, state) => _page(state, const SettingsPage()),
          ),
          GoRoute(
            path: '/student/profile/:userId',
            pageBuilder: (_, state) => _page(
              state,
              ProfilePage(userId: state.pathParameters['userId']!),
            ),
          ),
          GoRoute(
            path: '/student/courses/:courseId',
            pageBuilder: (_, state) => _page(
              state,
              CourseDetailPage(courseId: state.pathParameters['courseId']!),
            ),
          ),
          GoRoute(
            path: '/student/courses/:courseId/forums',
            pageBuilder: (_, state) => _page(
              state,
              CourseForumsPage(courseId: state.pathParameters['courseId']!),
            ),
          ),
          GoRoute(
            path: '/student/courses/:courseId/forums/:forumId',
            pageBuilder: (_, state) => _page(
              state,
              ForumThreadPage(
                courseId: state.pathParameters['courseId']!,
                forumId: state.pathParameters['forumId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/student/courses/:courseId/units/:unitId',
            pageBuilder: (_, state) => _page(
              state,
              UnitViewPage(
                courseId: state.pathParameters['courseId']!,
                unitId: state.pathParameters['unitId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/student/courses/:courseId/units/:unitId/assessment',
            pageBuilder: (_, state) => _page(
              state,
              AssessmentPage(
                courseId: state.pathParameters['courseId']!,
                unitId: state.pathParameters['unitId']!,
              ),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => AdminShellPage(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (_, state) => _page(state, const AdminHomeView()),
          ),
          GoRoute(
            path: '/admin/courses',
            pageBuilder: (_, state) => _page(state, const AdminCoursesPage()),
          ),
          GoRoute(
            path: '/admin/courses/:courseId',
            pageBuilder: (_, state) => _page(
              state,
              AdminCourseDetailPage(
                courseId: state.pathParameters['courseId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/courses/:courseId/:unitId',
            pageBuilder: (_, state) => _page(
              state,
              AdminUnitPlaceholderPage(
                courseId: state.pathParameters['courseId']!,
                unitId: state.pathParameters['unitId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/learning-paths',
            pageBuilder: (_, state) =>
                _page(state, const AdminLearningPathsPage()),
          ),
          GoRoute(
            path: '/admin/badges',
            pageBuilder: (_, state) => _page(state, const AdminBadgesPage()),
          ),
          GoRoute(
            path: '/admin/users',
            pageBuilder: (_, state) => _page(state, const AdminUsersPage()),
          ),
        ],
      ),
    ],
  );
});

Page<void> _page(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

class SkillForgeApp extends ConsumerStatefulWidget {
  const SkillForgeApp({super.key});

  @override
  ConsumerState<SkillForgeApp> createState() => _SkillForgeAppState();
}

class _SkillForgeAppState extends ConsumerState<SkillForgeApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sessionProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final router = ref.watch(routerProvider);

    final darkMode = session.user?.preference.darkModeEnabled ?? true;

    return MaterialApp.router(
      title: 'SkillForge',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) =>
          AppBackdrop(child: child ?? const SizedBox.shrink()),
    );
  }
}
