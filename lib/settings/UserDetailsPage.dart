import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDetailsPage extends StatefulWidget {
  final User? user;

  UserDetailsPage({required this.user});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController _oldPasswordController = TextEditingController();
    final TextEditingController _newPasswordController = TextEditingController();
    final TextEditingController _reEnterNewPasswordController = TextEditingController();
    String errorMessage = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
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
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Change'),
              onPressed: () async {
                String oldPassword = _oldPasswordController.text;
                String newPassword = _newPasswordController.text;
                String reEnterNewPassword = _reEnterNewPasswordController.text;

                // Validation
                if (newPassword == oldPassword) {
                  setState(() {
                    errorMessage = 'New Password must be different from Old Password';
                  });
                  return;
                }

                if (newPassword != reEnterNewPassword) {
                  setState(() {
                    errorMessage = 'Password Mismatch';
                  });
                  return;
                }

                // Call the method to change the password using Firebase
                await _changePassword(oldPassword, newPassword);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.user!.email!,
        password: oldPassword,
      );

      // User re-authenticated, now update the password
      await userCredential.user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully!')),
      );
    } catch (e) {
      // Handle error (e.g., incorrect old password)
      if (e is FirebaseAuthException && e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Old Password Incorrect')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
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
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Name'),
              subtitle: Text(widget.user?.displayName ?? 'N/A'),
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
              onTap: _showChangePasswordDialog,
            ),
            Divider(),
            ListTile(
              title: Text('Update Profile Picture'),
              leading: Icon(Icons.photo),
              onTap: () {
                // Implement update profile picture functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
