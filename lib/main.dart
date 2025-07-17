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
        //platform: TargetPlatform.android, // Forces Android behavior
        fontFamily: 'Abel', // Sets the font family
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: Login_Page.id,
      routes: {
        Register_Page.id: (context) => Register_Page(),
        Login_Page.id: (context) => Login_Page(),
        Forgot_Password.id: (context) => Forgot_Password(),
        Teacher_Home_Page.id: (context) => Teacher_Home_Page(),
        // Remove Parent_Home_Page from routes since it needs parameters
      },
      onGenerateRoute: (settings) {
        // Handle parameterized routes
        if (settings.name == Parent_Home_Page.id) {
          final args = settings.arguments as Map<String, dynamic>?;
          final schoolName = args?['schoolName'] as String? ?? 'Default School';
          final className = args?['className'] as String? ?? 'Default Class';
          final studentClass = args?['studentClass'] as String? ?? 'Default Student Class';
          final studentName = args?['studentName'] as String? ?? 'Default Student Name';
          return MaterialPageRoute(
            builder: (context) => Parent_Home_Page(
              schoolName: schoolName,
              className: className,
              studentClass: studentClass,
              studentName: studentName,
            ),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => NotFoundPage());
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