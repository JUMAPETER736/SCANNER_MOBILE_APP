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
  List<String> _selectedClasses = [];
  List<String> _selectedSubjects = [];

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
        title: Text('User Details', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: _username.isEmpty
            ? Center(child: CircularProgressIndicator())
            : _buildUserDetails(),
      ),
    );
  }

  Widget _buildUserDetails() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSettingsItem(Icons.person, 'Username', _username.isNotEmpty ? _username : 'N/A'),
        _buildSettingsItem(Icons.email, 'Email', widget.user?.email ?? 'N/A'),
        _buildSettingsItem(Icons.class_, 'Selected Classes', _selectedClasses.isNotEmpty ? _selectedClasses.join(', ') : 'N/A'),
        _buildSettingsItem(Icons.subject, 'Selected Subjects', _selectedSubjects.isNotEmpty ? _selectedSubjects.join(', ') : 'N/A'),
        SizedBox(height: 20),
        _buildSettingsActionItem('Change Password', Icons.lock, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordPage(user: widget.user),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.black, fontSize: 16)),
        leading: Icon(icon, color: Colors.blueAccent, size: 28),
      ),
    );
  }

  Widget _buildSettingsActionItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          title: Text(title, style: TextStyle(color: Colors.blueAccent, fontSize: 20)),
          leading: Icon(icon, color: Colors.blueAccent, size: 28),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
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
