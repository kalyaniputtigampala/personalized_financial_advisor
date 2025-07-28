import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1993C4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Us',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission Statement
                  _buildSection(
                    title: 'Our Mission',
                    content: 'At Clever Spenders, we believe that managing your finances should be a breeze, not a burden. Our mission is to empower you to take control of your financial life with confidence. We understand that money management can be overwhelming, which is why we\'ve designed our app to be simple, insightful, and stress-free.',
                    icon: Icons.flag_rounded,
                  ),

                  const SizedBox(height: 24),

                  // Vision Statement
                  _buildSection(
                    title: 'Our Vision',
                    content: 'Imagine having all the tools you need to track your expenses, set financial goals, and make informed decisions about your spending—all in one place. That\'s exactly what we offer!',
                    icon: Icons.visibility_rounded,
                  ),

                  const SizedBox(height: 32),

                  // Key Features Header
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Features List with alternating layout
                  _buildFeatureCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Effortless Expense Tracking',
                    description: 'Say goodbye to the hassle of keeping track of your daily spending! With Clever Spenders, you can easily log your expenses across various categories, ensuring you never lose sight of your finances.',
                    isIconLeft: true,
                  ),

                  _buildFeatureCard(
                    icon: Icons.dashboard_rounded,
                    title: 'Personalized Financial Dashboard',
                    description: 'Get a quick snapshot of your financial health. Our dashboard gives you an overview of your income, expenses, and savings, making it easy to see where you stand at a glance.',
                    isIconLeft: false,
                  ),

                  _buildFeatureCard(
                    icon: Icons.insights_rounded,
                    title: 'Visual Spending Insights',
                    description: 'Dive deep into your spending habits with our interactive charts and graphs. We make financial analysis easy and visually appealing, so you can understand your patterns and make smarter choices.',
                    isIconLeft: true,
                  ),

                  _buildFeatureCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Smart Spending Targets',
                    description: 'Want to stick to a budget? Set and monitor your spending targets for different categories. We\'ll help you stay on track and avoid overspending, so you can reach your financial goals.',
                    isIconLeft: false,
                  ),

                  _buildFeatureCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Timely Reminders',
                    description: 'Never miss a bill or important financial task again! Our customizable reminders keep you organized and ensure you\'re always on top of your commitments.',
                    isIconLeft: true,
                  ),

                  _buildFeatureCard(
                    icon: Icons.calculate_rounded,
                    title: 'Tax Calculation Assistance',
                    description: 'Tax season doesn\'t have to be stressful. Our integrated tax calculation tool simplifies your tax planning, helping you manage your finances effectively throughout the year.',
                    isIconLeft: false,
                  ),

                  _buildFeatureCard(
                    icon: Icons.security_rounded,
                    title: 'Secure Profile Management',
                    description: 'Your financial data is precious, and we take its security seriously. With our secure profile management features, you can rest assured that your information is safe and accessible whenever you need it.',
                    isIconLeft: true,
                  ),

                  const SizedBox(height: 32),

                  // Call to Action
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1993C4).withOpacity(0.1),
                          const Color(0xFF1993C4).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF1993C4).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.rocket_launch_rounded,
                          size: 48,
                          color: Color(0xFF1993C4),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Join Our Journey',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join us on this journey to financial empowerment! With Clever Spenders, you\'re not just managing money; you\'re building a brighter financial future.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF5A6B7D),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1993C4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1993C4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6B7D),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isIconLeft,
  }) {
    Widget iconWidget = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1993C4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF1993C4),
        size: 22,
      ),
    );

    Widget textWidget = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5A6B7D),
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isIconLeft
            ? [
          iconWidget,
          const SizedBox(width: 16),
          textWidget,
        ]
            : [
          textWidget,
          const SizedBox(width: 16),
          iconWidget,
        ],
      ),
    );
  }
}