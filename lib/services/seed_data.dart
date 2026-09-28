import '../models/challenge_model.dart';
import '../models/learning_model.dart';

class SeedData {
  SeedData._();

  
  static const List<LearningModel> learning = [
    LearningModel(
      id: 'learn-budgeting',
      title: 'Budgeting 101 for Students',
      category: 'Budgeting',
      summary: 'The 50-30-20 rule explained with a student budget.',
      emoji: '📊',
      readMinutes: 5,
      content:
          'A budget is simply a plan for your money.\n\n'
          'The 50-30-20 rule splits your income into three buckets:\n'
          '• 50% for needs — food, transport, rent, books.\n'
          '• 30% for wants — entertainment, shopping, eating out.\n'
          '• 20% for savings — your future self will thank you.\n\n'
          'Start by writing down what you earn each month. Then set a limit '
          'for each category in the Budget tab. Review weekly, adjust '
          'monthly. Small consistent changes beat dramatic ones.',
    ),
    LearningModel(
      id: 'learn-saving',
      title: 'How to Save as a Student',
      category: 'Saving',
      summary: 'Pay yourself first and automate small amounts.',
      emoji: '🐖',
      readMinutes: 4,
      content:
          'Saving is not about what is left over — it is about what you set '
          'aside first.\n\n'
          '1. Pay yourself first: move 10-20% the day money arrives.\n'
          '2. Automate it so you never have to decide.\n'
          '3. Name your goal. "New laptop" beats "savings".\n'
          '4. Track progress weekly. Momentum is motivating.\n\n'
          'Even 200 rupees a day becomes 73,000 in a year.',
    ),
    LearningModel(
      id: 'learn-needs-wants',
      title: 'Needs vs Wants',
      category: 'Needs vs Wants',
      summary: 'A simple test to stop impulse spending.',
      emoji: '⚖️',
      readMinutes: 3,
      content:
          'Needs keep you going: food, transport, study material, bills.\n'
          'Wants make life fun but can wait: new sneakers, extra takeout.\n\n'
          'The 24-hour rule: before any non-essential purchase, wait a day. '
          'If you still want it tomorrow, it is probably fine. If you forgot '
          'about it, you just saved money.',
    ),
    LearningModel(
      id: 'learn-income',
      title: 'Managing Irregular Income',
      category: 'Income Management',
      summary: 'Budget for months when money is unpredictable.',
      emoji: '💼',
      readMinutes: 4,
      content:
          'Freelance and part-time income lands unevenly.\n\n'
          '• Calculate a "baseline" from your lowest recent month.\n'
          '• Budget needs from the baseline only.\n'
          '• Put windfalls straight into savings or debt.\n'
          '• Keep a one-month buffer to smooth the gaps.',
    ),
    LearningModel(
      id: 'learn-debt',
      title: 'Avoiding Student Debt Traps',
      category: 'Income Management',
      summary: 'Know the difference between good and bad borrowing.',
      emoji: '🧾',
      readMinutes: 5,
      content:
          'Borrowing for education can pay off. Borrowing for lifestyle '
          'rarely does.\n\n'
          '• Never borrow for wants.\n'
          '• Understand the interest rate before signing.\n'
          '• Pay the smallest balance first for motivation.\n'
          '• Never take a new loan to pay an old one.',
    ),
    LearningModel(
      id: 'learn-invest',
      title: 'First Steps to Investing',
      category: 'Investing',
      summary: 'Emergency fund first, then slow and steady.',
      emoji: '📈',
      readMinutes: 6,
      content:
          'Before investing, you need three things:\n'
          '1. A 3-month emergency fund.\n'
          '2. No high-interest debt.\n'
          '3. A stable income baseline.\n\n'
          'Then start small and diversify. Time in the market beats timing '
          'the market. Never invest money you need next month.',
    ),
  ];

  
  
  static List<ChallengeModel> challenges(String userId) => [
        ChallengeModel(
          id: 'challenge-30day-$userId',
          title: '30 Days Saving Challenge',
          description:
              'Save a little every single day for 30 days and build the habit.',
          targetDays: 30,
          reward: '500 points + Saver badge',
          emoji: '🏆',
        ),
        ChallengeModel(
          id: 'challenge-nospend-$userId',
          title: 'No-Spend Weekend',
          description: 'Survive a weekend without non-essential spending.',
          targetDays: 2,
          reward: '150 points',
          emoji: '🚫',
        ),
        ChallengeModel(
          id: 'challenge-log-$userId',
          title: '7 Day Log Streak',
          description: 'Log every expense for 7 consecutive days.',
          targetDays: 7,
          reward: '200 points',
          emoji: '🔥',
        ),
        ChallengeModel(
          id: 'challenge-receipt-$userId',
          title: 'Receipt Master',
          description: 'Scan 10 receipts to sharpen your tracking.',
          targetDays: 10,
          reward: '300 points',
          emoji: '📸',
        ),
      ];
}
