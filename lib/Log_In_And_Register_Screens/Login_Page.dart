

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:scanna/Log_In_And_Register_Screens/Google_Done.dart';
import 'package:scanna/Log_In_And_Register_Screens/Forgot_Password.dart';
import 'package:scanna/Home_Screens/Teacher_Home_Page.dart';
import 'package:scanna/Home_Screens/Parent_Home_Page.dart';
import 'package:scanna/Log_In_And_Register_Screens/Register_Page.dart';

class Login_Page extends StatefulWidget {
  static String id = '/LoginPage';

  @override
  _Login_PageState createState() => _Login_PageState();
}

class _Login_PageState extends State<Login_Page> {
  // Firebase and Google Sign-In instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form data
  String email = '';
  String password = '';
  String studentName = '';
  String studentClass = '';

  // UI state variables
  bool _showSpinner = false;
  bool _isPasswordVisible = false;
  bool _isTeacherMode = true; // Default to teacher mode

  // Error state variables
  bool _wrongEmail = false;
  bool _wrongPassword = false;
  bool _emptyEmailField = false;
  bool _emptyPasswordField = false;
  bool _emptyStudentNameField = false;
  bool _emptyStudentClassField = false;
  bool _emailNotRegistered = false;
  String _errorMessage = '';
  String _emailErrorMessage = '';
  String _passwordErrorMessage = '';
  String _studentNameErrorMessage = '';
  String _studentClassErrorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _showSpinner,
        color: Colors.blueAccent,
        progressIndicator: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        child: Container(
          decoration: _buildBackgroundDecoration(),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: _getResponsivePadding(context),
                    child: Column(
                      children: [
                        SizedBox(height: _getResponsiveSpacing(context, 20.0)),
                        _buildHeader(context),
                        SizedBox(height: _getResponsiveSpacing(context, 24.0)),
                        _buildToggleButtons(context),
                        SizedBox(height: _getResponsiveSpacing(context, 24.0)),
                        if (_isTeacherMode) ...[
                          _buildEmailField(context),
                          SizedBox(height: _getResponsiveSpacing(context, 16.0)),
                          _buildPasswordField(context),
                          _buildForgotPasswordLink(context),
                        ] else ...[
                          _buildStudentNameField(context),
                          SizedBox(height: _getResponsiveSpacing(context, 16.0)),
                          _buildStudentClassField(context),
                        ],
                        // General Error Message Display
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: _getResponsiveSpacing(context, 8.0)),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: _getResponsiveFontSize(context, 18.0),
                                  ),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: _getResponsiveFontSize(context, 14.0),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(height: _getResponsiveSpacing(context, 24.0)),
                        _buildLoginButton(context),
                        if (_isTeacherMode) ...[
                          SizedBox(height: _getResponsiveSpacing(context, 20.0)),
                          _buildDivider(context),
                          SizedBox(height: _getResponsiveSpacing(context, 20.0)),
                          _buildSocialMediaButtons(context),
                        ],
                        Expanded(child: Container()),
                        if (_isTeacherMode) _buildSignUpLink(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== UI BUILDING METHODS ====================

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blueAccent.withOpacity(0.1),
          Colors.white,
          Colors.blueAccent.withOpacity(0.05),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _getResponsiveFontSize(context, 50.0),
            height: _getResponsiveFontSize(context, 50.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.login,
              size: _getResponsiveFontSize(context, 26.0),
              color: Colors.white,
            ),
          ),
          SizedBox(height: _getResponsiveSpacing(context, 8.0)),
          Text(
            'Login',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 30.0),
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        color: Colors.grey.withOpacity(0.1),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isTeacherMode = true;
                  _clearAllErrors();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: _isTeacherMode ? Colors.blueAccent : Colors.transparent,
                  boxShadow: _isTeacherMode ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      color: _isTeacherMode ? Colors.white : Colors.blueAccent,
                      size: _getResponsiveFontSize(context, 20.0),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Teacher',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 16.0),
                        color: _isTeacherMode ? Colors.white : Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isTeacherMode = false;
                  _clearAllErrors();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: !_isTeacherMode ? Colors.blueAccent : Colors.transparent,
                  boxShadow: !_isTeacherMode ? [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people,
                      color: !_isTeacherMode ? Colors.white : Colors.blueAccent,
                      size: _getResponsiveFontSize(context, 20.0),
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Parent',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 16.0),
                        color: !_isTeacherMode ? Colors.white : Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return _buildStyledTextField(
      label: 'Email Address',
      icon: Icons.email,
      obscureText: false,
      keyboardType: TextInputType.emailAddress,
      showError: _emptyEmailField || _wrongEmail || _emailNotRegistered,
      errorText: _emailErrorMessage,
      onChanged: (value) {
        email = value;
        setState(() {
          _wrongEmail = false;
          _emailNotRegistered = false;
          _emptyEmailField = false;
          _emailErrorMessage = '';
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return _buildStyledTextField(
      label: 'Password',
      icon: Icons.lock,
      obscureText: !_isPasswordVisible,
      keyboardType: TextInputType.visiblePassword,
      showError: _emptyPasswordField || _wrongPassword,
      errorText: _passwordErrorMessage,
      onChanged: (value) {
        password = value;
        setState(() {
          _wrongPassword = false;
          _emptyPasswordField = false;
          _passwordErrorMessage = '';
          _errorMessage = '';
        });
      },
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.blueAccent,
          size: _getResponsiveFontSize(context, 20.0),
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      ),
    );
  }

  Widget _buildStudentNameField(BuildContext context) {
    return _buildStyledTextField(
      label: 'Student Name',
      icon: Icons.person,
      obscureText: false,
      keyboardType: TextInputType.name,
      showError: _emptyStudentNameField,
      errorText: _studentNameErrorMessage,
      onChanged: (value) {
        studentName = value;
        setState(() {
          _emptyStudentNameField = false;
          _studentNameErrorMessage = '';
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildStudentClassField(BuildContext context) {
    return _buildStyledTextField(
      label: 'Class',
      icon: Icons.class_,
      obscureText: false,
      keyboardType: TextInputType.text,
      showError: _emptyStudentClassField,
      errorText: _studentClassErrorMessage,
      onChanged: (value) {
        studentClass = value;
        setState(() {
          _emptyStudentClassField = false;
          _studentClassErrorMessage = '';
          _errorMessage = '';
        });
      },
    );
  }

  Widget _buildForgotPasswordLink(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: _getResponsiveSpacing(context, 8.0)),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, Forgot_Password.id);
          },
          child: Text(
            'Forgot Password',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 22.0),
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return Container(
      height: _getResponsiveFontSize(context, 48.0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isTeacherMode ? _login : _parentLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: Text(
          _isTeacherMode ? 'Log In' : 'Continue as Parent',
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context, 22.0),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 22.0),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            context,
            'Google',
            'assets/images/google.png',
                () => _signInWithSocialMedia('google'),
          ),
        ),
        SizedBox(width: _getResponsiveSpacing(context, 4.0)),
        Expanded(
          child: _buildSocialButton(
            context,
            'Facebook',
            'assets/images/facebook.png',
                () => _signInWithSocialMedia('facebook'),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context, String text, String imagePath, VoidCallback onPressed) {
    return Container(
      height: _getResponsiveFontSize(context, 44.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(imagePath, width: _getResponsiveFontSize(context, 18.0)),
        label: Text(
          text,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context, 22.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _getResponsiveSpacing(context, 2.0)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getResponsiveFontSize(context, 20.0),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, Register_Page.id);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveFontSize(context, 20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required String label,
    required IconData icon,
    required bool obscureText,
    Function(String)? onChanged,
    bool showError = false,
    String? errorText,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: _getResponsiveFontSize(context, 16.0)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blueAccent,
            fontSize: _getResponsiveFontSize(context, 16.0),
            fontWeight: FontWeight.w500,
          ),
          errorText: showError ? errorText : null,
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: _getResponsiveFontSize(context, 12.0),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: _getResponsiveFontSize(context, 20.0)),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.0),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
    );
  }

  // ==================== RESPONSIVE HELPER METHODS ====================

  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double widthScale = screenWidth / 375.0; // Base width (iPhone X)
    double heightScale = screenHeight / 812.0; // Base height (iPhone X)
    double scale = (widthScale + heightScale) / 2;

    double responsiveFontSize = baseFontSize * scale;
    return responsiveFontSize < 22.0 ? 22.0 : responsiveFontSize;
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double basePadding = screenWidth * 0.06; // 6% of screen width
    return EdgeInsets.symmetric(
      horizontal: basePadding.clamp(16.0, 32.0),
      vertical: 12.0,
    );
  }

  double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    double screenHeight = MediaQuery.of(context).size.height;
    double scale = screenHeight / 812.0; // Base height
    return (baseSpacing * scale).clamp(baseSpacing * 0.5, baseSpacing * 1.5);
  }

  // ==================== AUTHENTICATION METHODS ====================

  Future<void> _login() async {
    // Clear all previous errors
    setState(() {
      _wrongEmail = false;
      _wrongPassword = false;
      _emptyEmailField = false;
      _emptyPasswordField = false;
      _emailNotRegistered = false;
      _errorMessage = '';
      _emailErrorMessage = '';
      _passwordErrorMessage = '';
    });

    // Validate inputs
    bool hasErrors = false;

    if (email.trim().isEmpty) {
      setState(() {
        _emptyEmailField = true;
        _emailErrorMessage = 'Email address is required';
      });
      hasErrors = true;
    }

    if (password.trim().isEmpty) {
      setState(() {
        _emptyPasswordField = true;
        _passwordErrorMessage = 'Password is required';
      });
      hasErrors = true;
    }

    // If there are validation errors, don't proceed with login
    if (hasErrors) {
      return;
    }

    // Start loading
    setState(() {
      _showSpinner = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        // Navigate to Teacher Home Page
        Navigator.pushNamedAndRemoveUntil(
            context,
            Teacher_Home_Page.id,
                (route) => false
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseAuthException(e);
    } catch (e) {
      setState(() {
        _showSpinner = false;
        _errorMessage = "An error occurred. Please try again.";
      });
    }
  }

  Future<void> _parentLogin() async {
    // Clear all previous errors
    setState(() {
      _emptyStudentNameField = false;
      _emptyStudentClassField = false;
      _errorMessage = '';
      _studentNameErrorMessage = '';
      _studentClassErrorMessage = '';
    });

    // Validate inputs
    bool hasErrors = false;

    if (studentName.trim().isEmpty) {
      setState(() {
        _emptyStudentNameField = true;
        _studentNameErrorMessage = 'Student name is required';
      });
      hasErrors = true;
    }

    if (studentClass.trim().isEmpty) {
      setState(() {
        _emptyStudentClassField = true;
        _studentClassErrorMessage = 'Class is required';
      });
      hasErrors = true;
    }

    // If there are validation errors, don't proceed
    if (hasErrors) {
      return;
    }

    // Start loading
    setState(() {
      _showSpinner = true;
    });

    try {
      // Validate student name and class against Firebase
      bool isValidStudent = await _validateStudentInFirebase(studentName.trim(), studentClass.trim());

      // Stop loading
      setState(() {
        _showSpinner = false;
      });

      if (isValidStudent) {
        // Navigate to Parent Home Page
        Navigator.pushNamedAndRemoveUntil(
            context,
            Parent_Home_Page.id,
                (route) => false
        );
      } else {
        setState(() {
          _errorMessage = "Student not found. Please check the name and class.";
          _emptyStudentNameField = true;
          _emptyStudentClassField = true;
          _studentNameErrorMessage = "Student not found";
          _studentClassErrorMessage = "Invalid class";
        });
      }

    } catch (e) {
      setState(() {
        _showSpinner = false;
        _errorMessage = "Error validating student information. Please try again.";
      });
      print('Parent login error: $e');
    }
  }

  Future<bool> _validateStudentInFirebase(String studentName, String studentClass) async {
    try {
      // Split the student name to get first and last name
      List<String> nameParts = studentName.toUpperCase().split(' ');
      if (nameParts.length < 2) {
        return false; // Need both first and last name
      }

      String firstName = nameParts[0];
      String lastName = nameParts[1];

      // Construct the Firebase path
      String documentPath = 'Schools/Bwaila Secondary School/Classes/${studentClass.toUpperCase()}/Student_Details/${firstName} ${lastName}/Personal_Information/Registered_Information';

      // Query Firebase
      DocumentSnapshot doc = await _firestore.doc(documentPath).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Verify the data matches
        String dbFirstName = data['firstName']?.toString().toUpperCase() ?? '';
        String dbLastName = data['lastName']?.toString().toUpperCase() ?? '';
        String dbClass = data['studentClass']?.toString().toUpperCase() ?? '';

        // Check if names and class match
        bool nameMatch = (dbFirstName == firstName && dbLastName == lastName);
        bool classMatch = (dbClass == studentClass.toUpperCase());

        return nameMatch && classMatch;
      }

      return false;
    } catch (e) {
      print('Firebase validation error: $e');
      return false;
    }
  }

  void _clearAllErrors() {
    setState(() {
      _wrongEmail = false;
      _wrongPassword = false;
      _emptyEmailField = false;
      _emptyPasswordField = false;
      _emptyStudentNameField = false;
      _emptyStudentClassField = false;
      _emailNotRegistered = false;
      _errorMessage = '';
      _emailErrorMessage = '';
      _passwordErrorMessage = '';
      _studentNameErrorMessage = '';
      _studentClassErrorMessage = '';

      // Clear form data when switching modes
      email = '';
      password = '';
      studentName = '';
      studentClass = '';
    });
  }

  void _handleFirebaseAuthException(FirebaseAuthException e) {
    setState(() {
      _showSpinner = false;
      switch (e.code) {
        case 'wrong-password':
          _wrongPassword = true;
          _passwordErrorMessage = "Incorrect password";
          _errorMessage = "Incorrect password. Please try again.";
          break;
        case 'user-not-found':
          _emailNotRegistered = true;
          _emailErrorMessage = "Email not registered";
          _errorMessage = "No account found with this email address.";
          break;
        case 'invalid-email':
          _wrongEmail = true;
          _emailErrorMessage = "Invalid email format";
          _errorMessage = "Please enter a valid email address.";
          break;
        case 'too-many-requests':
          _errorMessage = "Too many failed attempts. Please try again later.";
          break;
        case 'user-disabled':
          _errorMessage = "This account has been disabled. Contact support.";
          break;
        case 'invalid-credential':
          _wrongEmail = true;
          _wrongPassword = true;
          _emailErrorMessage = "Incorrect Email";
          _passwordErrorMessage = "Incorrect Password";
          break;
        case 'network-request-failed':
          _errorMessage = "Network error. Please check your internet connection.";
          break;
        default:
          _errorMessage = "Login failed. Please check your email and password.";
          print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
    });
  }

  Future<void> _signInWithSocialMedia(String provider) async {
    if (provider == 'google') {
      await _handleGoogleSignIn(context);
    } else if (provider == 'facebook') {
      await _handleFacebookSignIn(context);
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() {
      _showSpinner = true;
    });

    User? user = await _performGoogleSignIn();

    setState(() {
      _showSpinner = false;
    });

    if (user != null) {
      // For social media login, we assume it's a teacher login
      // You can modify this logic based on your needs
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Google_Done(user, _googleSignIn),
        ),
      );
    } else {
      _showToast("Google sign-in failed");
    }
  }

  Future<void> _handleFacebookSignIn(BuildContext context) async {
    setState(() {
      _showSpinner = true;
    });

    User? user = await _performFacebookSignIn();

    setState(() {
      _showSpinner = false;
    });

    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Teacher_Home_Page(),
        ),
      );
    } else {
      _showToast("Facebook sign-in failed");
    }
  }

  Future<User?> _performGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      print('Google sign-in error: $e');
      return null;
    }
  }

  Future<User?> _performFacebookSignIn() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final AuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      print('Facebook sign-in error: $e');
      return null;
    }
    return null;
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}