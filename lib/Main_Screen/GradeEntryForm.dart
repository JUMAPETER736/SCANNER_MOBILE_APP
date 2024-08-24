import 'package:flutter/material.dart';

class GradeEntryForm extends StatefulWidget {
  @override
  _GradeEntryFormState createState() => _GradeEntryFormState();
}

class _GradeEntryFormState extends State<GradeEntryForm> {
  final _formKey = GlobalKey<FormState>();
  String? _subject;
  String? _grade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Grade')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject'),
                onSaved: (value) => _subject = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Grade'),
                onSaved: (value) => _grade = value,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Save grade here
                  }
                },
                child: Text('Save Grade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
