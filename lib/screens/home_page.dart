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
          return data['name'] as String;
        }).toList();

        // Show alert dialog with today's reminders
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTodaysRemindersAlert(reminders);
        });
      }
    });
  }


  void _showTodaysRemindersAlert(List<String> reminders) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notification_important, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            // Fixed: Added Expanded to prevent title overflow
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
                  Expanded(child: Text(reminder)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
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

              // Expenses Scatter Plot
              _buildExpensesScatterPlot(),
              const SizedBox(height: 24),

              // Reminders Section
              _buildRemindersSection(),
            ],
          ),
        ),
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

  Widget _buildExpensesScatterPlot() {
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
          const Text(
            'Monthly Expenses Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _currentUserId != null
                ? StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('expenses')
                  .where('userId', isEqualTo: _currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expense data available\nAdd some expenses to see the chart',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                // Process data to get monthly totals
                final monthlyTotals = _calculateMonthlyTotals(snapshot.data!.docs);

                if (monthlyTotals.isEmpty) {
                  return const Center(
                    child: Text(
                      'No expense data available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return _buildScatterChart(monthlyTotals);
              },
            )
                : const Center(
              child: Text(
                'Please log in to view your expenses',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, double> _calculateMonthlyTotals(List<QueryDocumentSnapshot> docs) {
    Map<int, double> monthlyTotals = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final date = (data['date'] as Timestamp).toDate();

      // Create a unique key for each month (YYYYMM format)
      final monthKey = date.year * 100 + date.month;

      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
    }

    return monthlyTotals;
  }

  Widget _buildScatterChart(Map<int, double> monthlyTotals) {
    if (monthlyTotals.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Convert monthly totals to scatter plot spots
    final spots = <ScatterSpot>[];
    final sortedKeys = monthlyTotals.keys.toList()..sort();

    for (int i = 0; i < sortedKeys.length; i++) {
      final monthKey = sortedKeys[i];
      final amount = monthlyTotals[monthKey]!;
      spots.add(ScatterSpot(i.toDouble(), amount));
    }

    final maxAmount = monthlyTotals.values.reduce((a, b) => a > b ? a : b);
    final minAmount = monthlyTotals.values.reduce((a, b) => a < b ? a : b);

    return ScatterChart(
      ScatterChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minAmount * 0.8, // Add some padding
        maxY: maxAmount * 1.2, // Add some padding
        scatterSpots: spots,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedKeys.length) {
                  final monthKey = sortedKeys[index];
                  final year = monthKey ~/ 100;
                  final month = monthKey % 100;

                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

                  return Text(
                    '${months[month - 1]}\n${year.toString().substring(2)}',
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.center,
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxAmount / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey.withOpacity(0.3)),
            bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipItems: (ScatterSpot touchedSpot) {
              final index = touchedSpot.x.toInt();
              if (index >= 0 && index < sortedKeys.length) {
                final monthKey = sortedKeys[index];
                final year = monthKey ~/ 100;
                final month = monthKey % 100;

                const months = ['January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'];

                return ScatterTooltipItem(
                  '${months[month - 1]} $year\n₹${touchedSpot.y.toStringAsFixed(0)}',
                );
              }
              return ScatterTooltipItem('');
            },
          ),
        ),
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