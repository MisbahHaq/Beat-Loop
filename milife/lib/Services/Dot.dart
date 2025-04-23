import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DotMatrix extends StatefulWidget {
  const DotMatrix({super.key});

  @override
  State<DotMatrix> createState() => _DotMatrixState();
}

class _DotMatrixState extends State<DotMatrix> {
  List<Map<String, String>> birthdays = [];
  final _nameController = TextEditingController();
  DateTime? _selectedDate;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadBirthdays();
  }

  Future<void> _loadBirthdays() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('birthdays');
    if (saved != null) {
      setState(() {
        birthdays = List<Map<String, String>>.from(jsonDecode(saved));
      });
    }
  }

  Future<void> _saveBirthdays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birthdays', jsonEncode(birthdays));
  }

  void _addOrUpdateBirthday() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedDate == null) return;

    final formattedDate =
        "${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year}";

    if (_editingIndex != null) {
      setState(() {
        birthdays[_editingIndex!] = {'name': name, 'date': formattedDate};
        _editingIndex = null;
      });
    } else {
      setState(() {
        birthdays.add({'name': name, 'date': formattedDate});
      });
    }

    _nameController.clear();
    _selectedDate = null;
    _saveBirthdays(); // save after UI update
  }

  void _deleteBirthday(int index) {
    setState(() {
      birthdays.removeAt(index);
    });
    _saveBirthdays();
  }

  void _editBirthday(int index) {
    final birthday = birthdays[index];
    _nameController.text = birthday['name']!;
    final dateParts = birthday['date']!.split('-');
    _selectedDate = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );
    setState(() {
      _editingIndex = index;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No Date Chosen'
                        : 'Selected: ${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    'Pick Date',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _addOrUpdateBirthday,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              icon: Icon(
                _editingIndex != null ? Icons.edit : Icons.add,
                color: Colors.white,
              ),
              label: Text(
                _editingIndex != null ? 'Update Birthday' : 'Add Birthday',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  birthdays.isEmpty
                      ? const Center(
                        child: Text(
                          'No birthdays added.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : ListView.builder(
                        itemCount: birthdays.length,
                        itemBuilder: (context, index) {
                          final birthday = birthdays[index];
                          return Card(
                            color: Colors.transparent,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                birthday['name']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                birthday['date']!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.amber,
                                    ),
                                    onPressed: () => _editBirthday(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteBirthday(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
