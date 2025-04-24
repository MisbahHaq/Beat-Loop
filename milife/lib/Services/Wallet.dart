// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // For formatting dates
// import 'package:fl_chart/fl_chart.dart'; // For the graph
// import 'package:shared_preferences/shared_preferences.dart';

// class WalletPage extends StatefulWidget {
//   const WalletPage({super.key});

//   @override
//   State<WalletPage> createState() => _WalletPageState();
// }

// class _WalletPageState extends State<WalletPage> {
//   List<Map<String, dynamic>> expenses = [];

//   bool showWeekly = true; // To toggle between weekly and monthly view
//   Map<String, dynamic>? recentlyDeletedExpense;

//   @override
//   void initState() {
//     super.initState();
//     _loadExpenses();
//   }

//   // Load expenses from SharedPreferences
//   Future<void> _loadExpenses() async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String>? savedExpenses = prefs.getStringList('expenses');
//     if (savedExpenses != null) {
//       setState(() {
//         expenses =
//             savedExpenses.map((expense) {
//               final parts = expense.split(',');
//               return {
//                 'id': int.parse(parts[0]),
//                 'name': parts[1],
//                 'amount': double.parse(parts[2]),
//                 'date': DateTime.parse(parts[3]),
//               };
//             }).toList();
//       });
//     }
//   }

//   // Save expenses to SharedPreferences
//   Future<void> _saveExpense() async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> expenseStrings =
//         expenses.map((e) {
//           return '${e['id']},${e['name']},${e['amount']},${e['date']}';
//         }).toList();
//     prefs.setStringList('expenses', expenseStrings);
//   }

//   // Function to get weekly expenses
//   List<Map<String, dynamic>> getWeeklyExpenses() {
//     DateTime now = DateTime.now();
//     DateTime startOfWeek = now.subtract(
//       Duration(days: now.weekday - 1),
//     ); // Start of this week
//     return expenses.where((expense) {
//       return expense['date'].isAfter(startOfWeek);
//     }).toList();
//   }

//   // Function to get monthly expenses
//   List<Map<String, dynamic>> getMonthlyExpenses() {
//     DateTime now = DateTime.now();
//     return expenses.where((expense) {
//       return expense['date'].month == now.month &&
//           expense['date'].year == now.year;
//     }).toList();
//   }

//   // Function to calculate total expense from filtered expenses
//   double calculateTotal(List<Map<String, dynamic>> filteredExpenses) {
//     double total = 0;
//     for (var expense in filteredExpenses) {
//       total += expense['amount'];
//     }
//     return total;
//   }

//   // Function to add a new expense with a dialog
//   void _addExpense() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         String name = '';
//         double amount = 0.0;

//         return AlertDialog(
//           title: const Text("Add New Expense"),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 onChanged: (value) {
//                   name = value;
//                 },
//                 decoration: const InputDecoration(labelText: "Expense Name"),
//               ),
//               TextField(
//                 onChanged: (value) {
//                   amount = double.tryParse(value) ?? 0.0;
//                 },
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: "Amount"),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   final newExpense = {
//                     "id": DateTime.now().millisecondsSinceEpoch,
//                     "name": name,
//                     "amount": amount,
//                     "date": DateTime.now(),
//                   };
//                   expenses.add(newExpense);
//                   _saveExpense(); // Save the updated expenses to SharedPreferences
//                 });
//                 Navigator.pop(context);
//               },
//               child: const Text("Add"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text("Cancel"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Function to edit an expense with a dialog
//   void _editExpense(int id) {
//     final index = expenses.indexWhere((e) => e['id'] == id);
//     if (index != -1) {
//       String name = expenses[index]['name'];
//       double amount = expenses[index]['amount'];

//       showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text("Edit Expense"),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: TextEditingController(text: name),
//                   onChanged: (value) {
//                     name = value;
//                   },
//                   decoration: const InputDecoration(labelText: "Expense Name"),
//                 ),
//                 TextField(
//                   controller: TextEditingController(text: amount.toString()),
//                   keyboardType: TextInputType.number,
//                   onChanged: (value) {
//                     amount = double.tryParse(value) ?? 0.0;
//                   },
//                   decoration: const InputDecoration(labelText: "Amount"),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   setState(() {
//                     expenses[index]['name'] = name;
//                     expenses[index]['amount'] = amount;
//                     _saveExpense(); // Save the updated expenses to SharedPreferences
//                   });
//                   Navigator.pop(context);
//                 },
//                 child: const Text("Save"),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text("Cancel"),
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }

//   // Function to delete an expense with undo feature
//   void _deleteExpense(int id) {
//     final deletedExpense = expenses.firstWhere(
//       (element) => element['id'] == id,
//     );
//     setState(() {
//       expenses.removeWhere((element) => element['id'] == id);
//       _saveExpense(); // Save the updated expenses to SharedPreferences
//     });

//     // Show undo Snackbar
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('${deletedExpense['name']} removed'),
//         action: SnackBarAction(
//           label: 'Undo',
//           onPressed: () {
//             setState(() {
//               expenses.add(deletedExpense); // Add the expense back
//               _saveExpense(); // Save the updated expenses to SharedPreferences
//             });
//           },
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Filter expenses based on weekly or monthly selection
//     List<Map<String, dynamic>> filteredExpenses =
//         showWeekly ? getWeeklyExpenses() : getMonthlyExpenses();

//     double totalExpense = calculateTotal(filteredExpenses);

//     return Scaffold(
//       backgroundColor: Colors.black45,
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
//         ),
//         backgroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add, color: Colors.white),
//             onPressed: _addExpense,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Toggle button for weekly/monthly view
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               TextButton(
//                 onPressed: () {
//                   setState(() {
//                     showWeekly = true;
//                   });
//                 },
//                 child: const Text(
//                   "Weekly",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               TextButton(
//                 onPressed: () {
//                   setState(() {
//                     showWeekly = false;
//                   });
//                 },
//                 child: const Text(
//                   "Monthly",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//           // Graph to show the total expense
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: SizedBox(
//               height: 200, // Define the height of the chart
//               width:
//                   double
//                       .infinity, // Make it take up the full width of the screen
//               child: BarChart(
//                 BarChartData(
//                   titlesData: FlTitlesData(show: false),
//                   borderData: FlBorderData(show: false),
//                   barGroups: [
//                     BarChartGroupData(
//                       x: 0,
//                       barRods: [
//                         BarChartRodData(
//                           toY: totalExpense,
//                           color: Colors.white,
//                           width: 10,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           // Displaying the filtered list of expenses
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: filteredExpenses.length,
//               itemBuilder: (context, index) {
//                 final expense = filteredExpenses[index];
//                 return Dismissible(
//                   key: Key(expense['id'].toString()),
//                   onDismissed: (direction) {
//                     _deleteExpense(expense['id']);
//                   },
//                   background: Container(color: Colors.red),
//                   child: Card(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: ListTile(
//                       title: Text(expense['name']),
//                       subtitle: Text("Rs. ${expense['amount']}"),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.edit),
//                         onPressed: () => _editExpense(expense['id']),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  List<Map<String, dynamic>> expenses = [];
  bool showWeekly = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedExpenses = prefs.getStringList('expenses');
    if (savedExpenses != null) {
      setState(() {
        expenses =
            savedExpenses
                .map((e) => Map<String, dynamic>.from(json.decode(e)))
                .toList();
      });
    }
  }

  Future<void> _saveExpenses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedExpenses = expenses.map((e) => json.encode(e)).toList();
    prefs.setStringList('expenses', encodedExpenses);
  }

  void _addExpense() {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Add Expense',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0;
                  if (name.isNotEmpty && amount > 0) {
                    setState(() {
                      expenses.add({
                        'name': name,
                        'amount': amount,
                        'date': DateTime.now().toIso8601String(),
                      });
                    });
                    _saveExpenses();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
    _saveExpenses();
  }

  void _editExpense(int index) {
    TextEditingController nameController = TextEditingController(
      text: expenses[index]['name'],
    );
    TextEditingController amountController = TextEditingController(
      text: expenses[index]['amount'].toString(),
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Edit Expense',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    expenses[index]['name'] = nameController.text;
                    expenses[index]['amount'] =
                        double.tryParse(amountController.text) ?? 0;
                  });
                  _saveExpenses();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  List<Map<String, dynamic>> get filteredExpenses {
    final now = DateTime.now();
    return expenses.where((expense) {
      final date = DateTime.tryParse(expense['date'] ?? '') ?? now;
      if (showWeekly) {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(weekStart.subtract(const Duration(days: 1)));
      } else {
        return date.month == now.month && date.year == now.year;
      }
    }).toList();
  }

  double get totalExpense {
    return filteredExpenses.fold(
      0,
      (sum, e) => sum + (e['amount'] as num).toDouble(),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> get _barChartData {
    Map<int, double> dailyTotals = {};
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      dailyTotals[i] = 0.0;
    }

    for (var e in filteredExpenses) {
      final date = DateTime.tryParse(e['date'] ?? '');
      if (date != null) {
        final diff = now.difference(date).inDays;
        if (diff >= 0 && diff < 7) {
          dailyTotals[6 - diff] =
              (dailyTotals[6 - diff] ?? 0) + (e['amount'] as num).toDouble();
        }
      }
    }

    return dailyTotals.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: Colors.white,
            width: 14,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: _addExpense,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showWeekly ? "This Week's Total" : "This Month's Total",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Rs. ${totalExpense.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildToggleButton("Weekly", showWeekly, () {
                  setState(() => showWeekly = true);
                }),
                _buildToggleButton("Monthly", !showWeekly, () {
                  setState(() => showWeekly = false);
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: false),
                  barGroups: _barChartData,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredExpenses.length,
              itemBuilder: (context, index) {
                final expense = filteredExpenses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rs. ${expense['amount']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => _editExpense(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteExpense(index),
                      ),
                    ],
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
