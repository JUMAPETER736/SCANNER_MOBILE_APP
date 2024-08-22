import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: UserManagementPage(),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _username = '';
  String errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> registerUser(String email, String password, String username) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': username,
        'email': email,
      });

      fetchUsername(userCredential.user!);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to register: $e';
      });
    }
  }

  Future<void> fetchUsername(User user) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        setState(() {
          _username = snapshot['name'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: FirebaseAuth.instance.currentUser!.email!,
        password: oldPassword,
      );

      // User re-authenticated, now update the password
      await userCredential.user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully!')),
      );
      Navigator.of(context).pop(); // Go back to user details after success
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to change password: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _username.isEmpty ? _buildRegistrationForm() : _buildUserDetails(),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Username'),
        ),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'Password'),
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
            String email = _emailController.text.trim();
            String password = _passwordController.text.trim();
            String username = _nameController.text.trim();

            if (email.isEmpty || password.isEmpty || username.isEmpty) {
              setState(() {
                errorMessage = 'Please fill in all fields.';
              });
              return;
            }

            await registerUser(email, password, username);
          },
          child: Text('Register'),
        ),
      ],
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
          subtitle: Text(FirebaseAuth.instance.currentUser?.email ?? 'N/A'),
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
          content: Column(
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
                    errorMessage = 'Password Mismatch';
                  });
                  return;
                }

                await changePassword(oldPassword, newPassword);
              },
              child: Text('Change Password'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
