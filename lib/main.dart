import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scanna/Log_In_And_Register_Screens/Forgot_Password.dart';
import 'package:scanna/Log_In_And_Register_Screens/Login_Page.dart';
import 'package:scanna/Log_In_And_Register_Screens/Register_Page.dart';
import 'package:scanna/Home_Screens/Teacher_Home_Page.dart';
import 'Home_Screens/Parent_Home_Page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Abel',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/Login_Page',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/Login_Page':
            return MaterialPageRoute(builder: (context) => Login_Page());
          case '/Register_Page':
            return MaterialPageRoute(builder: (context) => Register_Page());
          case '/Forgot_Password':
            return MaterialPageRoute(builder: (context) => Forgot_Password());
          case '/Teacher_Home_Page':
            return MaterialPageRoute(builder: (context) => Teacher_Home_Page());
          case '/Parent_Main_Home_Page':
            final args = settings.arguments as Map<String, String>?;
            return MaterialPageRoute(
              builder: (context) => Parent_Home_Page(
                schoolName: args?['schoolName'] ?? '',
                className: args?['className'] ?? '',
                studentClass: args?['studentClass'] ?? '',
                studentName: args?['studentName'] ?? '',
              ),
            );
          default:
            return MaterialPageRoute(builder: (context) => NotFoundPage());
        }
      },
    );
  }
}

class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sorry Page Not Found'),
      ),
      body: Center(
        child: Text('404 - Page Not Found'),
      ),
    );
  }
}