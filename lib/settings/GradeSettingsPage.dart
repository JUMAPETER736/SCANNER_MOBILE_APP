import 'package:flutter/material.dart';

class GradeSettingsPage extends StatefulWidget {
  @override
  _GradeSettingsPageState createState() => _GradeSettingsPageState();
}

class _GradeSettingsPageState extends State<GradeSettingsPage> {
  List<Map<String, dynamic>> _gradeScale = [
    {"label": "Fail", "min": 0, "max": 39},
    {"label": "Pass", "min": 40, "max": 59},
    {"label": "Credit", "min": 60, "max": 79},
    {"label": "Distinction", "min": 80, "max": 100},
  ];

  void _editGradeRange(int index) {
    final gradeRange = _gradeScale[index];
    TextEditingController labelController = TextEditingController(text: gradeRange['label']);
    TextEditingController minController = TextEditingController(text: gradeRange['min'].toString());
    TextEditingController maxController = TextEditingController(text: gradeRange['max'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Grade Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Minimum Score'),
              ),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Maximum Score'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _gradeScale[index] = {
                    "label": labelController.text,
                    "min": int.parse(minController.text),
                    "max": int.parse(maxController.text),
                  };
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addGradeRange() {
    TextEditingController labelController = TextEditingController();
    TextEditingController minController = TextEditingController();
    TextEditingController maxController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Grade Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Minimum Score'),
              ),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Maximum Score'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _gradeScale.add({
                    "label": labelController.text,
                    "min": int.parse(minController.text),
                    "max": int.parse(maxController.text),
                  });
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeGradeRange(int index) {
    setState(() {
      _gradeScale.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grade Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize Your Grading Scale',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _gradeScale.length,
                itemBuilder: (context, index) {
                  final gradeRange = _gradeScale[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                          '${gradeRange["label"]}: ${gradeRange["min"]}-${gradeRange["max"]}%'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editGradeRange(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeGradeRange(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addGradeRange,
              child: Text('Add Grade Range'),
            ),
          ],
        ),
      ),
    );
  }
}
