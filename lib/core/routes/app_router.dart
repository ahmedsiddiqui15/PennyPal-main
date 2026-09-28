import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/content/admin_content_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/support/admin_support_screen.dart';
import '../../features/admin/users/admin_users_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/onboarding/onboarding_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/splash/splash_screen.dart';
import '../../features/auth/verify_email/verify_email_screen.dart';
import '../../features/student/ai_assistant/ai_assistant_screen.dart';
import '../../features/student/budget/budget_screen.dart';
import '../../features/student/dashboard/dashboard_screen.dart';
import '../../features/student/expenses/add_expense_screen.dart';
import '../../features/student/expenses/expense_detail_screen.dart';
import '../../features/student/expenses/expenses_screen.dart';
import '../../features/student/gamification/gamification_screen.dart';
import '../../features/student/income/add_income_screen.dart';
import '../../features/student/income/income_screen.dart';
import '../../features/student/insights/insights_screen.dart';
import '../../features/student/learning/article_detail_screen.dart';
import '../../features/student/learning/learning_screen.dart';
import '../../features/student/notifications/notifications_screen.dart';
import '../../features/student/profile/about_screen.dart';
import '../../features/student/profile/edit_profile_screen.dart';
import '../../features/student/profile/profile_screen.dart';
import '../../features/student/profile/settings_screen.dart';
import '../../features/student/reports/reports_screen.dart';
import '../../features/student/savings/savings_screen.dart';
import '../../features/student/shell/student_shell.dart';
import '../../features/student/subscriptions/subscriptions_screen.dart';
import '../../features/student/support/support_screen.dart';
import '../../features/student/transactions/transactions_screen.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/splash_providers.dart';
import '../widgets/state_views.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => refresh.value++);
  ref.listen(settingsProvider, (_, __) => refresh.value++);
  ref.listen(splashHoldProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState auth = ref.read(authProvider);
      final SettingsState settings = ref.read(settingsProvider);
      final bool splashReady = ref.read(splashHoldProvider);
      final String location = state.matchedLocation;

      const Set<String> authRoutes = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      };
      final bool isSplash = location == AppRoutes.splash;
      final bool isOnboarding = location == AppRoutes.onboarding;
      final bool isAuthRoute = authRoutes.contains(location);
      final bool isVerify = location == AppRoutes.verifyEmail;

      
      
      if (auth.initializing || !splashReady) {
        return isSplash ? null : AppRoutes.splash;
      }

      
      if (!auth.isAuthenticated) {
        if (isSplash) {
          return settings.onboardingSeen
              ? AppRoutes.login
              : AppRoutes.onboarding;
        }
        if (isAuthRoute || isOnboarding) return null;
        return AppRoutes.login;
      }

      
      final String home = auth.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home;

      
      
      if (!auth.emailVerified) {
        return isVerify ? null : AppRoutes.verifyEmail;
      }
      if (isVerify) return home;

      if (isSplash || isAuthRoute || isOnboarding) return home;

      
      if (auth.isAdmin && location.startsWith(AppRoutes.studentRoot)) {
        return AppRoutes.adminDashboard;
      }
      if (!auth.isAdmin && location.startsWith(AppRoutes.adminRoot)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: <RouteBase>[
      
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),

      
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            StudentShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.expenses,
              builder: (_, __) => const ExpensesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.budget,
              builder: (_, __) => const BudgetScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.savings,
              builder: (_, __) => const SavingsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),

      
      GoRoute(
        path: AppRoutes.income,
        builder: (_, __) => const IncomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addIncome,
        builder: (_, __) => const AddIncomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addExpense,
        builder: (_, __) => const AddExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenseDetail,
        builder: (_, GoRouterState state) => ExpenseDetailScreen(
          expenseId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        builder: (_, __) => const TransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (_, __) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (_, __) => const AiAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.insights,
        builder: (_, __) => const InsightsScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamification,
        builder: (_, __) => const GamificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptions,
        builder: (_, __) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.learning,
        builder: (_, __) => const LearningScreen(),
      ),
      GoRoute(
        path: AppRoutes.articleDetail,
        builder: (_, GoRouterState state) => ArticleDetailScreen(
          articleId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (_, GoRouterState state) => SupportScreen(
          initialTab: state.uri.queryParameters['tab'] == 'contact' ? 1 : 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),

      
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            AdminShell(navigationShell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              builder: (_, __) => const AdminDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminUsers,
              builder: (_, __) => const AdminUsersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminContent,
              builder: (_, __) => const AdminContentScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminSupport,
              builder: (_, __) => const AdminSupportScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: ErrorView(
        title: 'Page not found',
        message: 'We could not find "${state.uri}".',
        onRetry: () => context.go(AppRoutes.splash),
      ),
    ),
  );
});
