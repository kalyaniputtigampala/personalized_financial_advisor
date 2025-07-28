import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _remindersCollection = 'reminders';

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _deleteExpiredReminders();
    _checkTodaysReminders();
  }

  // Check for today's reminders and show alert
  void _checkTodaysReminders() {
    if (_currentUserId == null) return;

    final today = DateTime.now();
    final todayString = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    _firestore
        .collection(_remindersCollection)
        .where('userId', isEqualTo: _currentUserId)
        .where('date', isEqualTo: todayString)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final reminders = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] as String,
          };
        }).toList();

        // Show alert dialog with today's reminders
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTodaysRemindersAlert(reminders);
        });
      }
    });
  }

  Future<void> _deleteExpiredReminders() async {
    if (_currentUserId == null) return;

    try {
      final today = DateTime.now();

      // Get all reminders for current user
      final querySnapshot = await _firestore
          .collection(_remindersCollection)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final batch = _firestore.batch();
      int deletedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final reminderDate = data['date'] as String;

        // Parse reminder date (DD-MM-YYYY format)
        final dateParts = reminderDate.split('-');
        if (dateParts.length == 3) {
          try {
            final reminderDateTime = DateTime(
              int.parse(dateParts[2]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[0]), // day
            );

            // If reminder date is before today, mark for deletion
            if (reminderDateTime.isBefore(today)) {
              batch.delete(doc.reference);
              deletedCount++;
            }
          } catch (e) {
            // Skip invalid date formats
            print('Invalid date format in reminder: $reminderDate');
          }
        }
      }

      // Execute batch delete
      if (deletedCount > 0) {
        await batch.commit();
        print('Auto-deleted $deletedCount expired reminders');
      }
    } catch (e) {
      print('Error deleting expired reminders: $e');
    }
  }
  void _showTodaysRemindersAlert(List<Map<String, String>> reminders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notification_important, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Today\'s Reminders',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have reminders for today:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            ...reminders.map((reminder) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reminder['name']!)),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'These reminders will be automatically removed tomorrow',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Optional: Delete today's reminders immediately
              await _deleteTodaysReminders(reminders);
              Navigator.pop(context);
            },
            child: const Text('Got it & Remove Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTodaysReminders(List<Map<String, String>> reminders) async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();

      for (var reminder in reminders) {
        final docRef = _firestore.collection(_remindersCollection).doc(reminder['id']);
        batch.delete(docRef);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${reminders.length} reminder(s) removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Calculate monthly expenses for current year
  Map<int, double> _calculateMonthlyExpenses(List<QueryDocumentSnapshot> expenseDocs) {
    final Map<int, double> monthlyExpenses = {};
    final currentYear = DateTime.now().year;

    // Initialize all months with 0
    for (int i = 1; i <= 12; i++) {
      monthlyExpenses[i] = 0.0;
    }

    // Calculate expenses for each month
    for (var doc in expenseDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final date = (data['date'] as Timestamp).toDate();

      // Only include current year expenses
      if (date.year == currentYear) {
        monthlyExpenses[date.month] = (monthlyExpenses[date.month] ?? 0.0) + amount;
      }
    }

    return monthlyExpenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Cards
              _buildDashboardCards(),
              const SizedBox(height: 24),

              // Monthly Expenses Scatter Plot
              _buildMonthlyExpensesChart(),
              const SizedBox(height: 24),

              // Reminders Section
              _buildRemindersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyExpensesChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Monthly Expenses ${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: _currentUserId == null
                ? const Center(
              child: Text(
                'Please log in to view expenses chart',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('expenses')
                  .where('userId', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final expenseDocs = snapshot.data!.docs;

                if (expenseDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expenses data available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final monthlyExpenses = _calculateMonthlyExpenses(expenseDocs);
                final currentMonth = DateTime.now().month;

                // Filter expenses up to current month only
                final filteredExpenses = <int, double>{};
                for (int i = 1; i <= currentMonth; i++) {
                  filteredExpenses[i] = monthlyExpenses[i] ?? 0.0;
                }

                final maxAmount = filteredExpenses.values.isNotEmpty
                    ? filteredExpenses.values.reduce((a, b) => a > b ? a : b)
                    : 0.0;

                // Create line chart spots for connecting the dots
                final lineSpots = filteredExpenses.entries.map((entry) {
                  return FlSpot(entry.key.toDouble(), entry.value);
                }).toList();

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      drawHorizontalLine: false, // Remove horizontal grid lines
                      verticalInterval: 1,
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Months',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            const months = [
                              '',
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'May',
                              'Jun',
                              'Jul',
                              'Aug',
                              'Sep',
                              'Oct',
                              'Nov',
                              'Dec'
                            ];
                            if (value.toInt() >= 1 && value.toInt() <= currentMonth) {
                              return Text(
                                months[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // Hide Y-axis
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                        left: BorderSide(color: Colors.grey.shade400, width: 1),
                        right: BorderSide.none,
                        top: BorderSide.none,
                      ),
                    ),
                     // Clip the chart to prevent going outside bounds
                    minX: 1,
                    maxX: currentMonth.toDouble(),
                    minY: 0,
                    maxY: maxAmount > 0 ? maxAmount * 1.2 : 1000,
                    lineBarsData: [
                      LineChartBarData(
                        spots: lineSpots,
                        isCurved: true,
                        curveSmoothness: 0.2, // Reduced smoothness to prevent excessive curves
                        color: Colors.blue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        preventCurveOverShooting: true, // Prevent curve from going below minY
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 6,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.1),
                          applyCutOffY: true, // Apply cutoff to prevent area from going below minY
                          cutOffY: 0, // Set cutoff at Y = 0
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.blue.shade800,

                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            const months = [
                              '',
                              'January',
                              'February',
                              'March',
                              'April',
                              'May',
                              'June',
                              'July',
                              'August',
                              'September',
                              'October',
                              'November',
                              'December'
                            ];
                            return LineTooltipItem(
                              '${months[touchedSpot.x.toInt()]}\n₹${touchedSpot.y.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        // Handle touch events if needed
                      },
                      handleBuiltInTouches: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _currentUserId != null
          ? _firestore
          .collection('expenses')
          .where('userId', isEqualTo: _currentUserId)
          .snapshots()
          : null,
      builder: (context, expenseSnapshot) {
        double totalExpenses = 0.0;
        double currentMonthExpenses = 0.0;

        if (expenseSnapshot.hasData && expenseSnapshot.data!.docs.isNotEmpty) {
          final now = DateTime.now();
          final currentMonth = now.month;
          final currentYear = now.year;

          for (var doc in expenseSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final date = (data['date'] as Timestamp).toDate();

            totalExpenses += amount;

            if (date.month == currentMonth && date.year == currentYear) {
              currentMonthExpenses += amount;
            }
          }
        }

        // Fetch user's income from profile
        return StreamBuilder<DocumentSnapshot>(
          stream: _currentUserId != null
              ? _firestore
              .collection('users')
              .doc(_currentUserId)
              .snapshots()
              : null,
          builder: (context, userSnapshot) {
            double income = 0.0;

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              income = (userData['income'] as num?)?.toDouble() ?? 0.0;
            }

            final double savings = income - currentMonthExpenses;

            return Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Income',
                    amount: '₹${income.toStringAsFixed(0)}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Expenses',
                    amount: '₹${currentMonthExpenses.toStringAsFixed(0)}',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDashboardCard(
                    title: 'Savings',
                    amount: '₹${savings.toStringAsFixed(0)}',
                    color: savings >= 0 ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                FloatingActionButton(
                  mini: true,
                  onPressed: _showAddReminderDialog,
                  backgroundColor: const Color(0xFF1993C4),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          // Reminders List using StreamBuilder
          Container(
            padding: const EdgeInsets.all(16),
            child: _currentUserId == null
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Please log in to view reminders',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(_remindersCollection)
                  .where('userId', isEqualTo: _currentUserId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final reminders = snapshot.data!.docs;

                if (reminders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No reminders set',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: reminders.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final reminder = ReminderItem.fromMap(doc.id, data);
                    return _buildReminderItem(reminder);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(ReminderItem reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  reminder.date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
            onPressed: () => _showEditReminderDialog(reminder),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.grey[600], size: 20),
            onPressed: () => _deleteReminder(reminder.id),
          ),
        ],
      ),
    );
  }

  // Updated _showAddReminderDialog with alert info
  void _showAddReminderDialog() {
    final nameController = TextEditingController();
    final dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter reminder name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'DD-MM-YYYY',
                suffixIcon: Icon(Icons.notification_add),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  dateController.text = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                }
              },
              readOnly: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'An alert will be shown when you open the app on the selected date',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && dateController.text.isNotEmpty) {
                if (_currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please log in to add reminders')),
                  );
                  return;
                }
                await _addReminder(nameController.text, dateController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditReminderDialog(ReminderItem reminder) {
    final nameController = TextEditingController(text: reminder.name);
    final dateController = TextEditingController(text: reminder.date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.notification_add),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  dateController.text = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                }
              },
              readOnly: true,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'An alert will be shown when you open the app on the new date',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && dateController.text.isNotEmpty) {
                await _updateReminder(reminder.id, nameController.text, dateController.text, reminder.type);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Updated Firebase CRUD operations without notification scheduling
  Future<void> _addReminder(String name, String date) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add reminders')),
      );
      return;
    }

    try {
      // Add reminder to Firestore
      await _firestore.collection(_remindersCollection).add({
        'userId': _currentUserId,
        'name': name,
        'date': date,
        'type': 'reminder',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding reminder: $e')),
      );
    }
  }

  Future<void> _updateReminder(String id, String name, String date, String type) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to update reminders')),
      );
      return;
    }

    try {
      // First check if the reminder belongs to the current user
      final doc = await _firestore.collection(_remindersCollection).doc(id).get();
      if (!doc.exists || doc.data()?['userId'] != _currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized: Cannot update this reminder')),
        );
        return;
      }

      // Update reminder in Firestore
      await _firestore.collection(_remindersCollection).doc(id).update({
        'name': name,
        'date': date,
        'type': type,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating reminder: $e')),
      );
    }
  }

  Future<void> _deleteReminder(String id) async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to delete reminders')),
      );
      return;
    }

    try {
      // First check if the reminder belongs to the current user
      final doc = await _firestore.collection(_remindersCollection).doc(id).get();
      if (!doc.exists || doc.data()?['userId'] != _currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized: Cannot delete this reminder')),
        );
        return;
      }

      // Delete reminder from Firestore
      await _firestore.collection(_remindersCollection).doc(id).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting reminder: $e')),
      );
    }
  }
}



class ReminderItem {
  final String id;
  final String name;
  final String date;
  final String type;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReminderItem({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory ReminderItem.fromMap(String id, Map<String, dynamic> data) {
    return ReminderItem(
      id: id,
      name: data['name'] ?? '',
      date: data['date'] ?? '',
      type: data['type'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': date,
      'type': type,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}