import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TeaPage extends StatefulWidget {
  const TeaPage({super.key});

  @override
  State<TeaPage> createState() => _TeaPageState();
}

class _TeaPageState extends State<TeaPage> {
  List<Map<String, String>> notes = [];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getString('notes');
    if (savedNotes != null) {
      setState(() {
        notes = List<Map<String, String>>.from(jsonDecode(savedNotes));
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(notes));
  }

  void _addNote() {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    if (title.isNotEmpty && description.isNotEmpty) {
      setState(() {
        notes.add({'title': title, 'description': description});
        _titleController.clear();
        _descController.clear();
        _saveNotes();
      });
    }
  }

  void _deleteNote(int index) {
    setState(() {
      notes.removeAt(index);
      _saveNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Fields
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: _addNote,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Note',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            // Notes List
            Expanded(
              child:
                  notes.isEmpty
                      ? const Center(
                        child: Text(
                          'No notes yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Card(
                            color: Colors.black54,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                note['title']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                note['description']!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteNote(index),
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
