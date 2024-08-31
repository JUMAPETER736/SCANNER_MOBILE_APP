import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Details App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserDetailsPage(user: FirebaseAuth.instance.currentUser),
    );
  }
}

class UserDetailsPage extends StatefulWidget {
  final User? user;

  UserDetailsPage({required this.user});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  String _username = '';
  List<String> _selectedClasses = []; // List to store multiple classes
  List<String> _selectedSubjects = []; // List to store multiple subjects

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user?.uid)
          .get();
      if (snapshot.exists) {
        setState(() {
          _username = snapshot['name'] ?? '';
          _selectedClasses = List<String>.from(snapshot['classes'] ?? []);
          _selectedSubjects = List<String>.from(snapshot['subjects'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching User Details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _username.isEmpty
            ? Center(child: CircularProgressIndicator())
            : _buildUserDetails(),
      ),
    );
  }

  Widget _buildUserDetails() {
    return ListView(
      children: [
        Divider(),
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Username'),
          subtitle: Text(_username.isNotEmpty ? _username : 'N/A'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.email),
          title: Text('Email'),
          subtitle: Text(widget.user?.email ?? 'N/A'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.class_),
          title: Text('Selected Classes'),
          subtitle: Text(_selectedClasses.isNotEmpty ? _selectedClasses.join(', ') : 'N/A'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.subject),
          title: Text('Selected Subjects'),
          subtitle: Text(_selectedSubjects.isNotEmpty ? _selectedSubjects.join(', ') : 'N/A'),
        ),
        Divider(),
        ListTile(
          title: Text('Change Password'),
          leading: Icon(Icons.lock),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangePasswordPage(user: widget.user),
              ),
            );
          },
        ),
        Divider(),
      ],
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  final User? user;

  ChangePasswordPage({required this.user});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _reEnterNewPasswordController = TextEditingController();
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Old Password'),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: _reEnterNewPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Re-Enter New Password'),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _handleChangePassword,
                  child: Text('Change Password'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    String oldPassword = _oldPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String reEnterNewPassword = _reEnterNewPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || reEnterNewPassword.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (newPassword != reEnterNewPassword) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    await changePassword(oldPassword, newPassword);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.user?.email ?? '',
        password: oldPassword,
      );

      await userCredential.user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed Successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to change Password: $e';
      });
    }
  }
}
