import 'package:flutter/material.dart';
import 'package:scanna/results_screen/ForgotPassword.dart';
import 'package:scanna/main_screens/LoginPage.dart';
import 'package:scanna/main_screens/RegisterPage.dart';
import 'package:scanna/results_screen/Done.dart';
import 'package:firebase_core/firebase_core.dart';
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
      initialRoute: RegisterPage.id,
      routes: {
        RegisterPage.id: (context) => RegisterPage(),
        LoginPage.id: (context) => LoginPage(),
        ForgotPassword.id: (context) => ForgotPassword(),
        Done.id: (context) => Done(),
      },
    );
  }
}
