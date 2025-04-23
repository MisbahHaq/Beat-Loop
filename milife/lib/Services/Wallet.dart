import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:fl_chart/fl_chart.dart'; // For the graph
import 'package:shared_preferences/shared_preferences.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  List<Map<String, dynamic>> expenses = [];

  bool showWeekly = true; // To toggle between weekly and monthly view
  Map<String, dynamic>? recentlyDeletedExpense;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // Load expenses from SharedPreferences
  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedExpenses = prefs.getStringList('expenses');
    if (savedExpenses != null) {
      setState(() {
        expenses =
            savedExpenses.map((expense) {
              final parts = expense.split(',');
              return {
                'id': int.parse(parts[0]),
                'name': parts[1],
                'amount': double.parse(parts[2]),
                'date': DateTime.parse(parts[3]),
              };
            }).toList();
      });
    }
  }

  // Save expenses to SharedPreferences
  Future<void> _saveExpense() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> expenseStrings =
        expenses.map((e) {
          return '${e['id']},${e['name']},${e['amount']},${e['date']}';
        }).toList();
    prefs.setStringList('expenses', expenseStrings);
  }

  // Function to get weekly expenses
  List<Map<String, dynamic>> getWeeklyExpenses() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(
      Duration(days: now.weekday - 1),
    ); // Start of this week
    return expenses.where((expense) {
      return expense['date'].isAfter(startOfWeek);
    }).toList();
  }

  // Function to get monthly expenses
  List<Map<String, dynamic>> getMonthlyExpenses() {
    DateTime now = DateTime.now();
    return expenses.where((expense) {
      return expense['date'].month == now.month &&
          expense['date'].year == now.year;
    }).toList();
  }

  // Function to calculate total expense from filtered expenses
  double calculateTotal(List<Map<String, dynamic>> filteredExpenses) {
    double total = 0;
    for (var expense in filteredExpenses) {
      total += expense['amount'];
    }
    return total;
  }

  // Function to add a new expense with a dialog
  void _addExpense() {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        double amount = 0.0;

        return AlertDialog(
          title: const Text("Add New Expense"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  name = value;
                },
                decoration: const InputDecoration(labelText: "Expense Name"),
              ),
              TextField(
                onChanged: (value) {
                  amount = double.tryParse(value) ?? 0.0;
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  final newExpense = {
                    "id": DateTime.now().millisecondsSinceEpoch,
                    "name": name,
                    "amount": amount,
                    "date": DateTime.now(),
                  };
                  expenses.add(newExpense);
                  _saveExpense(); // Save the updated expenses to SharedPreferences
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Function to edit an expense with a dialog
  void _editExpense(int id) {
    final index = expenses.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      String name = expenses[index]['name'];
      double amount = expenses[index]['amount'];

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Edit Expense"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: name),
                  onChanged: (value) {
                    name = value;
                  },
                  decoration: const InputDecoration(labelText: "Expense Name"),
                ),
                TextField(
                  controller: TextEditingController(text: amount.toString()),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    amount = double.tryParse(value) ?? 0.0;
                  },
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    expenses[index]['name'] = name;
                    expenses[index]['amount'] = amount;
                    _saveExpense(); // Save the updated expenses to SharedPreferences
                  });
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );
    }
  }

  // Function to delete an expense with undo feature
  void _deleteExpense(int id) {
    final deletedExpense = expenses.firstWhere(
      (element) => element['id'] == id,
    );
    setState(() {
      expenses.removeWhere((element) => element['id'] == id);
      _saveExpense(); // Save the updated expenses to SharedPreferences
    });

    // Show undo Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedExpense['name']} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              expenses.add(deletedExpense); // Add the expense back
              _saveExpense(); // Save the updated expenses to SharedPreferences
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter expenses based on weekly or monthly selection
    List<Map<String, dynamic>> filteredExpenses =
        showWeekly ? getWeeklyExpenses() : getMonthlyExpenses();

    double totalExpense = calculateTotal(filteredExpenses);

    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addExpense,
          ),
        ],
      ),
      body: Column(
        children: [
          // Toggle button for weekly/monthly view
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    showWeekly = true;
                  });
                },
                child: const Text(
                  "Weekly",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    showWeekly = false;
                  });
                },
                child: const Text(
                  "Monthly",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          // Graph to show the total expense
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 200, // Define the height of the chart
              width:
                  double
                      .infinity, // Make it take up the full width of the screen
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: totalExpense,
                          color: Colors.black,
                          width: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Displaying the filtered list of expenses
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredExpenses.length,
              itemBuilder: (context, index) {
                final expense = filteredExpenses[index];
                return Dismissible(
                  key: Key(expense['id'].toString()),
                  onDismissed: (direction) {
                    _deleteExpense(expense['id']);
                  },
                  background: Container(color: Colors.red),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(expense['name']),
                      subtitle: Text("Rs. ${expense['amount']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editExpense(expense['id']),
                      ),
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
}
