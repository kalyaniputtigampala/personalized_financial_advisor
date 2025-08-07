import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class LogsPage extends StatefulWidget {
  const LogsPage({Key? key}) : super(key: key);

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _showAddForm = false;

  // Form controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Bills';

  // Track which alerts have been shown to avoid repetition
  final Set<String> _shownAlerts = <String>{};

  // Primary design color - consistent with your design system
  static const Color primaryColor = Color(0xFF1993C4);

  // Categories and their colors
  final List<String> _categories = [
    'Bills', 'Dining', 'Education', 'EMI', 'Fuel', 'Gadgets', 'Groceries',
    'Grooming', 'Health', 'Household', 'House Rent', 'Investment', 'Kids',
    'Entertainment', 'Office', 'Shopping', 'Travel','Others',
  ];

  final Map<String, Color> _categoryColors = {
    'Bills': Colors.pinkAccent,
    'Dining': Colors.purple,
    'Education': Colors.blue,
    'EMI': Colors.orange,
    'Fuel': Colors.brown,
    'Gadgets': Colors.cyan,
    'Groceries': Colors.green,
    'Grooming': Colors.lightGreen,
    'Health': Colors.teal,
    'Household': Colors.indigo,
    'House Rent': Colors.deepOrange,
    'Investment': Colors.deepPurple,
    'Kids': Colors.orangeAccent,
    'Entertainment': Colors.lime,
    'Office': Colors.blueGrey,
    'Shopping': Colors.amber,
    'Travel': Colors.lightBlue,
    'Others': Colors.lightGreenAccent,
  };

  @override
  void initState() {
    super.initState();
    // Listen for target progress changes
    _listenForTargetAlerts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Listen for target progress and show alerts when needed
  void _listenForTargetAlerts() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to both targets and expenses to track progress
    _firestore
        .collection('targets')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((targetSnapshot) {
      _firestore
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((expenseSnapshot) {
        _checkTargetProgress(targetSnapshot.docs, expenseSnapshot.docs);
      });
    });
  }

  // Check target progress and show alerts
  void _checkTargetProgress(List<QueryDocumentSnapshot> targetDocs, List<QueryDocumentSnapshot> expenseDocs) {
    final expensesByCategory = _calculateCurrentMonthCategoryTotals(expenseDocs);

    for (var doc in targetDocs) {
      final target = TargetItem.fromFirestore(doc);
      final currentAmount = expensesByCategory[target.category] ?? 0.0;
      final targetAmount = double.tryParse(target.amount) ?? 0.0;

      if (targetAmount > 0) {
        final progress = currentAmount / targetAmount;
        final alertKey = '${target.id}${DateTime.now().month}${DateTime.now().year}';

        // Check if we should show an alert and haven't shown it yet this month
        if (!_shownAlerts.contains(alertKey)) {
          if (progress >= 1.0) {
            // Target exceeded (100% or more)
            _showTargetExceededAlert(target, currentAmount, targetAmount, progress);
            _shownAlerts.add(alertKey);
          } else if (progress >= 0.8) {
            // Target approaching (80% or more)
            _showTargetApproachingAlert(target, currentAmount, targetAmount, progress);
            _shownAlerts.add(alertKey);
          }
        }
      }
    }
  }

  // Show alert when target is approaching (80-99%)
  void _showTargetApproachingAlert(TargetItem target, double currentAmount, double targetAmount, double progress) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final remaining = targetAmount - currentAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Target Alert',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${target.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${target.category}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'ve reached $percentage% of your target!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Spent: ₹${currentAmount.toStringAsFixed(0)} / ₹${targetAmount.toStringAsFixed(0)}'),
                    Text('Remaining: ₹${remaining.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'re getting close to your spending limit for ${target.category}. Consider reducing expenses in this category to stay within your budget.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _showAddForm = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Review Expenses', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Show alert when target is exceeded (100% or more)
  void _showTargetExceededAlert(TargetItem target, double currentAmount, double targetAmount, double progress) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final exceeded = currentAmount - targetAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Target Exceeded!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${target.name}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Category: ${target.category}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'ve exceeded your target by ${((progress - 1) * 100).toStringAsFixed(1)}%!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Target: ₹${targetAmount.toStringAsFixed(0)}'),
                    Text(
                      'Spent: ₹${currentAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Exceeded by: ₹${exceeded.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You\'re off track with your ${target.category} spending this month. Consider reviewing your recent expenses and adjusting your spending habits to get back on track.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Dismiss', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _showAddForm = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Review Expenses', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Get current month's start and end dates
  Map<String, DateTime> _getCurrentMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return {'start': startOfMonth, 'end': endOfMonth};
  }

  // Get month name for display
  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  // Add expense to Firestore with user ID
  Future<void> _addExpense() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      await _firestore.collection('expenses').add({
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'date': DateTime.now(),
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      _amountController.clear();
      _descriptionController.clear();
      setState(() => _showAddForm = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense added successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding expense: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Delete expense from Firestore
  Future<void> _deleteExpense(String docId) async {
    try {
      await _firestore.collection('expenses').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense deleted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Calculate category totals for current month only
  Map<String, double> _calculateCurrentMonthCategoryTotals(List<QueryDocumentSnapshot> docs) {
    final monthRange = _getCurrentMonthRange();
    final startOfMonth = monthRange['start']!;
    final endOfMonth = monthRange['end']!;

    Map<String, double> totals = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final expenseDate = (data['date'] as Timestamp).toDate();

      // Only include expenses from current month
      if (expenseDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        final category = data['category'] as String;
        final amount = (data['amount'] as num).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
      }
    }
    return totals;
  }

  // Calculate category totals for all time (for comparison)
  Map<String, double> _calculateAllTimeCategoryTotals(List<QueryDocumentSnapshot> docs) {
    Map<String, double> totals = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String;
      final amount = (data['amount'] as num).toDouble();
      totals[category] = (totals[category] ?? 0) + amount;
    }
    return totals;
  }

  // Build pie chart
  Widget _buildPieChart(Map<String, double> categoryTotals, String title) {
    final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    if (total == 0) {
      return _buildEmptyState(
        icon: Icons.show_chart,
        title: 'No Data Available',
        subtitle: 'Start adding expenses to see your chart',
      );
    }

    final sections = categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        color: _categoryColors[entry.key],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(categoryTotals, total),
      ],
    );
  }

  // Build legend
  Widget _buildLegend(Map<String, double> categoryTotals, double total) {
    return Column(
      children: categoryTotals.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _categoryColors[entry.key],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: _buildEmptyState(
            icon: Icons.login,
            title: 'Please Log In',
            subtitle: 'Log in to view your expenses',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      //backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () => setState(() => _showAddForm = !_showAddForm),
                      icon: Icon(_showAddForm ? Icons.close : Icons.add, color: Colors.white, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Add Expense Form
              if (_showAddForm) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.add, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Add New Expense',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                hintText: 'Enter amount',
                                prefixText: '₹',
                                prefixIcon: Icon(Icons.currency_rupee, color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Enter description',
                                prefixIcon: Icon(Icons.description, color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category, color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedCategory = value!),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _addExpense,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Save Expense', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _showAddForm = false),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Main Content
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('expenses')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.error_outline, size: 30, color: Colors.red.shade300),
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryColor));
                  }

                  final docs = snapshot.data!.docs;
                  final currentMonthTotals = _calculateCurrentMonthCategoryTotals(docs);
                  final allTimeTotals = _calculateAllTimeCategoryTotals(docs);
                  final currentMonthTotal = currentMonthTotals.values.fold(0.0, (sum, amount) => sum + amount);
                  final allTimeTotal = allTimeTotals.values.fold(0.0, (sum, amount) => sum + amount);

                  return Column(
                    children: [
                      // Latest Expenses Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.receipt_long, color: primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Recent Expenses',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: docs.isEmpty
                                  ? _buildEmptyState(
                                icon: Icons.receipt_long,
                                title: 'No Expenses Yet',
                                subtitle: 'Add your first expense to get started!',
                              )
                                  : Column(
                                children: docs.take(5).map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final date = (data['date'] as Timestamp).toDate();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _categoryColors[data['category']],
                                          radius: 20,
                                          child: Text(
                                            data['category'][0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['description'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${data['category']} • ${date.day}/${date.month}/${date.year}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹${data['amount'].toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () => _deleteExpense(doc.id),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red.shade400,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Monthly Expenses Chart
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              spreadRadius: 0,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.pie_chart, color: primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Expenses for ${_getCurrentMonthName()}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: _buildPieChart(currentMonthTotals, ''),
                            ),
                            Container(
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                              child: Column(
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total for ${_getCurrentMonthName()}:',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '₹${currentMonthTotal.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total All Time:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '₹${allTimeTotal.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model classes
class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;
  final String userId;

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
    required this.userId,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'description': description,
      'category': category,
      'date': date,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class TargetItem {
  final String id;
  final String name;
  final String amount;
  final String category;
  final String userId;

  TargetItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.userId,
  });

  factory TargetItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TargetItem(
      id: doc.id,
      name: data['name'] as String,
      amount: data['amount'] as String,
      category: data['category'] as String,
      userId: data['userId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}