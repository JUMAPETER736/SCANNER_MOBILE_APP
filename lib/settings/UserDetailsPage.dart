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
  TextEditingController _nameController = TextEditingController();
  String _username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    if (widget.user?.uid != null) {
      try {
        // Fetch user data from Firestore
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users') // Change to your collection name
            .doc(widget.user!.uid) // User's UID as the document ID
            .get();

        if (snapshot.exists) {
          setState(() {
            _username = snapshot['name'] ?? ''; // Adjusted to 'name'
            _nameController.text = _username; // Set the username in the controller
          });
        }
      } catch (e) {
        print('Error fetching username: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
              title: Text('Username'),
              subtitle: Text(_username.isNotEmpty ? _username : 'N/A'), // Display username from Firestore
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(user: widget.user),
                  ),
                );
              },
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
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _reEnterNewPasswordController.dispose();
    super.dispose();
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
      Navigator.of(context).pop(); // Go back to the UserDetailsPage after success
    } catch (e) {
      // Handle error (e.g., incorrect old password)
      if (e is FirebaseAuthException && e.code == 'wrong-password') {
        setState(() {
          errorMessage = 'Incorrect Old Password';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to change password: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String oldPassword = _oldPasswordController.text.trim();
                String newPassword = _newPasswordController.text.trim();
                String reEnterNewPassword = _reEnterNewPasswordController.text.trim();

                // Validation for empty fields
                if (oldPassword.isEmpty || newPassword.isEmpty || reEnterNewPassword.isEmpty) {
                  setState(() {
                    errorMessage = 'Please fill in all the fields';
                  });
                  return;
                }

                // Validation for matching new password
                if (newPassword != reEnterNewPassword) {
                  setState(() {
                    errorMessage = 'Password Mismatch';
                  });
                  return;
                }

                // Call the method to change the password using Firebase
                await _changePassword(oldPassword, newPassword);
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
