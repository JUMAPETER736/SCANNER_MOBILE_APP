import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scanna/Log_In_And_Register_Screens/ForgotPassword.dart';
import 'package:scanna/Log_In_And_Register_Screens/LoginPage.dart';
import 'package:scanna/Log_In_And_Register_Screens/RegisterPage.dart';
import 'package:scanna/Home_Screens/Main_Home.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Abel'),
      initialRoute: LoginPage.id,
      routes: {
        RegisterPage.id: (context) => RegisterPage(),
        LoginPage.id: (context) => LoginPage(),
        ForgotPassword.id: (context) => ForgotPassword(),
        Done.id: (context) => Done(),
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
        title: Text('Page Not Found'),
      ),
      body: Center(
        child: Text('404 - Page Not Found'),
      ),
    );
  }
}
