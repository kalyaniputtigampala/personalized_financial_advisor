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
        final alertKey = '${target.id}_${DateTime.now().month}_${DateTime.now().year}';

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
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 48,
          ),
          title: Text(
            'Target Alert',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${target.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Category: ${target.category}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'ve reached $percentage% of your target!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Spent: ₹${currentAmount.toStringAsFixed(0)} / ₹${targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Remaining: ₹${remaining.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'You\'re getting close to your spending limit for ${target.category}. Consider reducing expenses in this category to stay within your budget.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Scroll to the top to show recent expenses
                setState(() {
                  _showAddForm = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: Text('Review Expenses'),
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
          icon: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          title: Text(
            'Target Exceeded!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: ${target.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Category: ${target.category}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'ve exceeded your target by ${((progress - 1) * 100).toStringAsFixed(1)}%!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Target: ₹${targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Spent: ₹${currentAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Exceeded by: ₹${exceeded.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'You\'re off track with your ${target.category} spending this month. Consider reviewing your recent expenses and adjusting your spending habits to get back on track.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Close add form to focus on expenses list
                setState(() {
                  _showAddForm = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Review Expenses'),
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

    return {
      'start': startOfMonth,
      'end': endOfMonth,
    };
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
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
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
      setState(() {
        _showAddForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
    }
  }

  // Delete expense from Firestore
  Future<void> _deleteExpense(String docId) async {
    try {
      await _firestore.collection('expenses').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expense: $e')),
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
      if (expenseDate.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
          expenseDate.isBefore(endOfMonth.add(Duration(days: 1)))) {
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
      return Center(
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No expenses yet',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view your expenses',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Expenses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () => setState(() => _showAddForm = !_showAddForm),
                    backgroundColor: const Color(0xFF1993C4),
                    child: Icon(_showAddForm ? Icons.close : Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add Expense Form
              if (_showAddForm) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add New Expense',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            prefixText: '₹',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addExpense,
                                child: const Text('Save'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _showAddForm = false),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Main Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('expenses')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    final currentMonthTotals = _calculateCurrentMonthCategoryTotals(docs);
                    final allTimeTotals = _calculateAllTimeCategoryTotals(docs);
                    final currentMonthTotal = currentMonthTotals.values.fold(0.0, (sum, amount) => sum + amount);
                    final allTimeTotal = allTimeTotals.values.fold(0.0, (sum, amount) => sum + amount);

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Latest 5 Expenses
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Latest 5 Expenses',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (docs.isEmpty)
                                    const Center(
                                      child: Text(
                                        'No expenses yet. Add your first expense!',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    ...docs.take(5).map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final date = (data['date'] as Timestamp).toDate();

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _categoryColors[data['category']],
                                            child: Text(
                                              data['category'][0],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            data['description'],
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                            '${data['category']} • ${date.day}/${date.month}/${date.year}',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '₹${data['amount'].toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => _deleteExpense(doc.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Current Month Pie Chart
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildPieChart(currentMonthTotals, 'Expenses for ${_getCurrentMonthName()}'),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total for ${_getCurrentMonthName()}:',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '₹${currentMonthTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total All Time:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '₹${allTimeTotal.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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