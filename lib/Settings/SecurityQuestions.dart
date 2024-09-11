
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecurityQuestions extends StatefulWidget {
  @override
  _SecurityQuestionsState createState() => _SecurityQuestionsState();
}

class _SecurityQuestionsState extends State<SecurityQuestions> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _question1Controller = TextEditingController();
  final _question2Controller = TextEditingController();
  final _question3Controller = TextEditingController();

  Future<void> _saveSecurityQuestions() async {
    User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('users').doc(user.email).set({
        'security_questions': [
          _question1Controller.text,
          _question2Controller.text,
          _question3Controller.text,
        ],
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Security questions saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Questions', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Up Security Questions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                'Security questions help verify your identity in case you forget your password or need to recover your account.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              _buildSecurityQuestionField('What is your mother\'s maiden name?', _question1Controller),
              SizedBox(height: 20),
              _buildSecurityQuestionField('What was the name of your first pet?', _question2Controller),
              SizedBox(height: 20),
              _buildSecurityQuestionField('What was the name of your first school?', _question3Controller),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSecurityQuestions,
                child: Text('Save Security Questions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityQuestionField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  void dispose() {
    _question1Controller.dispose();
    _question2Controller.dispose();
    _question3Controller.dispose();
    super.dispose();
  }
}
