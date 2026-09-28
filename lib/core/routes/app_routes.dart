

class AppRoutes {
  AppRoutes._();

  
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';

  
  static const String studentRoot = '/app';
  static const String home = '/app/home';
  static const String expenses = '/app/expenses';
  static const String budget = '/app/budget';
  static const String savings = '/app/savings';
  static const String profile = '/app/profile';

  static const String income = '/app/income';
  static const String transactions = '/app/transactions';
  static const String reports = '/app/reports';
  static const String aiAssistant = '/app/assistant';
  static const String insights = '/app/insights';
  static const String gamification = '/app/rewards';
  static const String subscriptions = '/app/subscriptions';
  static const String learning = '/app/learning';
  static const String support = '/app/support';
  static const String notifications = '/app/notifications';
  static const String settings = '/app/settings';
  static const String about = '/app/about';
  static const String editProfile = '/app/profile/edit';

  static const String addExpense = '/app/expenses/new';
  static const String addIncome = '/app/income/new';

  
  static const String expenseDetail = '/app/expenses/:id';
  static String expenseDetailPath(String id) => '/app/expenses/$id';

  
  static const String articleDetail = '/app/learning/:id';
  static String articleDetailPath(String id) => '/app/learning/$id';

  
  static const String adminRoot = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminContent = '/admin/content';
  static const String adminSupport = '/admin/support';
}
