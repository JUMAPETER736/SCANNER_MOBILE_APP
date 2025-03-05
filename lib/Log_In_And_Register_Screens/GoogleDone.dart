import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDone extends StatelessWidget {
  final User? _user;
  final GoogleSignIn _googleSignIn;

  GoogleDone(this._user, this._googleSignIn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Done'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
             backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : AssetImage('assets/images/default_avatar.png') as ImageProvider,

              radius: 50.0,
            ),
            SizedBox(height: 20.0),
            Text(
              _user?.displayName ?? '',
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _googleSignIn.signOut();
                Navigator.pop(context);
              },
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
