import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails extends StatefulWidget {
  final User? user;

  UserDetails({required this.user});

  @override
  _UserDetailsState createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
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
      // Ensure the user is authenticated
      if (widget.user == null) {
        print('User is not authenticated.');
        return;
      }

      // Fetch user details from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Teachers_Details') // Access the Teachers_Details collection
          .doc(widget.user!.email) // Use the user's email as the document ID
          .get();

      // Check if the document exists
      if (userSnapshot.exists) {
        final data = userSnapshot.data() as Map<String, dynamic>?; // Cast data to Map

        setState(() {
          _username = (data != null && data.containsKey('name')) ? data['name'] : 'N/A';
          _selectedClasses = (data != null && data.containsKey('classes')) ? List<String>.from(data['classes']) : ['N/A'];
          _selectedSubjects = (data != null && data.containsKey('subjects')) ? List<String>.from(data['subjects']) : ['N/A'];
        });
      } else {
        print('User details not found for: ${widget.user!.email}');
        // Assign default values if document does not exist
        setState(() {
          _username = 'N/A';
          _selectedClasses = ['N/A'];
          _selectedSubjects = ['N/A'];
        });
      }
    } catch (e) {
      print('Error fetching User Details: $e');
      // Assign default values in case of error
      setState(() {
        _username = 'N/A';
        _selectedClasses = ['N/A'];
        _selectedSubjects = ['N/A'];
      });
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
        _buildSettingsActionItem('Change Password',  Icons.lock, () {
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
        title: Text(
            'Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _buildStyledTextField(
                controller: _oldPasswordController,
                labelText: 'Old Password',
              ),
              SizedBox(height: 16),
              _buildStyledTextField(
                controller: _newPasswordController,
                labelText: 'New Password',
              ),
              SizedBox(height: 16),
              _buildStyledTextField(
                controller: _reEnterNewPasswordController,
                labelText: 'Re-Enter New Password',
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
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        // Cancel button color
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        // Change Password button color
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handleChangePassword,
                      child: Text('Change Password', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        errorMessage = 'User is not logged in';
      });
      return;
    }

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
        errorMessage = 'New passwords do not match';
      });
      return;
    }

    await changePassword(oldPassword, newPassword);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      // Re-authenticate the user
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.user!.email!,
        password: oldPassword,
      );

      // Change the password
      await userCredential.user!.updatePassword(newPassword);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      if (e.code == 'wrong-password') {
        setState(() {
          errorMessage = 'Old Password is Incorrect';
        });
      } else {
        setState(() {
          errorMessage = 'Failed to change Password: ${e.message}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to change Password: ${e.toString()}';
      });
    }
  }
}