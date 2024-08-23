import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsPage extends StatefulWidget {
  final User? user;

  UserDetailsPage({required this.user});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  String _username = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  Future<void> fetchUsername() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.user?.uid).get();
      if (snapshot.exists) {
        setState(() {
          _username = snapshot['name'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
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
        child: _username.isEmpty ? CircularProgressIndicator() : _buildUserDetails(),
      ),
    );
  }

  Widget _buildUserDetails() {
    return ListView(
      children: [
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
          title: Text('Change Password'),
          leading: Icon(Icons.lock),
          onTap: () {
            _showChangePasswordDialog();
          },
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController _oldPasswordController = TextEditingController();
    final TextEditingController _newPasswordController = TextEditingController();
    final TextEditingController _reEnterNewPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
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
              },
              child: Text('Change Password'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.user?.email ?? '',
        password: oldPassword,
      );

      await userCredential.user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to change password: $e';
      });
    }
  }
}
