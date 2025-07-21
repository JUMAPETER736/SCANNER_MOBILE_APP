import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
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
        // Set Roboto as the default font family using Google Fonts
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        // You can also customize specific text styles
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        // Primary color scheme (optional)
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: Login_Page.id,
      routes: {
        Register_Page.id: (context) => Register_Page(),
        Login_Page.id: (context) => Login_Page(),
        Forgot_Password.id: (context) => Forgot_Password(),
        Teacher_Home_Page.id: (context) => Teacher_Home_Page(),
        Parent_Home_Page.id: (context) => Parent_Home_Page(),
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
        title: Text(
          'Sorry Page Not Found',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '404',
              style: GoogleFonts.roboto(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  Login_Page.id,
                      (route) => false,
                );
              },
              child: Text(
                'Go to Login',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}