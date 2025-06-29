import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanna/Log_In_And_Register_Screens/Google_Done.dart';
import 'package:scanna/Log_In_And_Register_Screens/Forgot_Password.dart';
import 'package:scanna/Home_Screens/Teacher_Home_Page.dart';
import 'package:scanna/Home_Screens/Parent_Home_Page.dart';
import 'package:scanna/Log_In_And_Register_Screens/Register_Page.dart';

// ==================== PARENT DATA MANAGER ====================
class ParentDataManager {
  static final ParentDataManager _instance = ParentDataManager._internal();
  factory ParentDataManager() => _instance;
  ParentDataManager._internal();

  String? _studentName;
  String? _studentClass;
  String? _firstName;
  String? _lastName;
  Map<String, dynamic>? _studentDetails;

  // Getters
  String? get studentName => _studentName;
  String? get studentClass => _studentClass;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  Map<String, dynamic>? get studentDetails => _studentDetails;

  // Set parent data
  void setParentData({
    required String studentName,
    required String studentClass,
    String? firstName,
    String? lastName,
    Map<String, dynamic>? studentDetails,
  }) {
    _studentName = studentName;
    _studentClass = studentClass;
    _firstName = firstName;
    _lastName = lastName;
    _studentDetails = studentDetails;
  }

  // Clear data (for logout)
  void clearData() {
    _studentName = null;
    _studentClass = null;
    _firstName = null;
    _lastName = null;
    _studentDetails = null;
  }

  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_studentName != null) await prefs.setString('parent_student_name', _studentName!);
    if (_studentClass != null) await prefs.setString('parent_student_class', _studentClass!);
    if (_firstName != null) await prefs.setString('parent_first_name', _firstName!);
    if (_lastName != null) await prefs.setString('parent_last_name', _lastName!);
    if (_studentDetails != null) {
      // Convert Timestamps to milliseconds since epoch
      Map<String, dynamic> sanitizedDetails = _convertTimestamps(_studentDetails!);
      String detailsJson = jsonEncode(sanitizedDetails);
      await prefs.setString('parent_student_details', detailsJson);
    }
  }

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.millisecondsSinceEpoch);
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _convertTimestamps(value));
      } else if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Map<String, dynamic>) {
            return _convertTimestamps(item);
          } else if (item is Timestamp) {
            return item.millisecondsSinceEpoch;
          }
          return item;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _studentName = prefs.getString('parent_student_name');
    _studentClass = prefs.getString('parent_student_class');
    _firstName = prefs.getString('parent_first_name');
    _lastName = prefs.getString('parent_last_name');

    String? detailsJson = prefs.getString('parent_student_details');
    if (detailsJson != null) {
      Map<String, dynamic> decoded = jsonDecode(detailsJson);
      _studentDetails = _restoreTimestamps(decoded);
    }
  }

  Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is int && (key.toLowerCase().contains('time') || key.toLowerCase().contains('date'))) {
        // Heuristic to identify timestamp fields - you might need to adjust this
        return MapEntry(key, Timestamp.fromMillisecondsSinceEpoch(value));
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _restoreTimestamps(value));
      } else if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Map<String, dynamic>) {
            return _restoreTimestamps(item);
          }
          return item;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }

  // Clear from SharedPreferences
  Future<void> clearFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('parent_student_name');
    await prefs.remove('parent_student_class');
    await prefs.remove('parent_first_name');
    await prefs.remove('parent_last_name');
    await prefs.remove('parent_student_details');
  }
}

// ==================== LOGIN PAGE CLASS ====================
class Login_Page extends StatefulWidget {
  static String id = '/LoginPage';

  @override
  _Login_PageState createState() => _Login_PageState();
}

class _Login_PageState extends State<Login_Page> {
  // ==================== FIREBASE INSTANCES ====================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== FORM DATA ====================
  String email = '';
  String password = '';
  String studentName = '';
  String studentClass = '';

  // ==================== UI STATE VARIABLES ====================
  bool _showSpinner = false;
  bool _isPasswordVisible = false;
  bool _isTeacherMode = true;

  // ==================== ERROR STATE VARIABLES ====================
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

  // ==================== LIFECYCLE METHODS ====================
  @override
  void initState() {
    super.initState();
    _checkExistingParentSession();
  }

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

                        // Form Fields
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

                        // Error Message Display
                        if (_errorMessage.isNotEmpty) _buildErrorMessage(context),

                        SizedBox(height: _getResponsiveSpacing(context, 24.0)),
                        _buildLoginButton(context),

                        // Social Media Login (Teacher Mode Only)
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
          _buildToggleButton(
            context,
            'Teacher',
            Icons.school,
            _isTeacherMode,
                () {
              setState(() {
                _isTeacherMode = true;
                _clearAllErrors();
              });
            },
          ),
          _buildToggleButton(
            context,
            'Parent',
            Icons.people,
            !_isTeacherMode,
                () {
              setState(() {
                _isTeacherMode = false;
                _clearAllErrors();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context, String text, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            boxShadow: isSelected ? [
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
                icon,
                color: isSelected ? Colors.white : Colors.blueAccent,
                size: _getResponsiveFontSize(context, 20.0),
              ),
              SizedBox(width: 8.0),
              Text(
                text,
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 16.0),
                  color: isSelected ? Colors.white : Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildErrorMessage(BuildContext context) {
    return Padding(
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
        onPressed: _isTeacherMode ? _teacherLogin : _parentLogin,
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
  Future<void> _teacherLogin() async {
    _clearAllErrors();

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

    if (hasErrors) return;

    setState(() {
      _showSpinner = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Teacher_Home_Page.id,
              (route) => false,
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

  // Updated parent login method
  Future<void> _parentLogin() async {
    _clearAllErrors();

    // Validate inputs
    bool hasErrors = false;

    if (studentName.trim().isEmpty) {
      setState(() {
        _emptyStudentNameField = true;
        _studentNameErrorMessage = 'Student name is required';
      });
      hasErrors = true;
    }

    if (hasErrors) return;

    setState(() {
      _showSpinner = true;
    });

    try {
      // Allow empty class for system-wide search
      bool isValidStudent = await _validateStudentInFirebase(
          studentName.trim(),
          studentClass.trim() // Can be empty for broader search
      );

      setState(() {
        _showSpinner = false;
      });

      if (isValidStudent) {
        _showToast('Welcome! Student found successfully.');

        Navigator.pushNamedAndRemoveUntil(
          context,
          Parent_Home_Page.id,
              (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = "Student not found in the system.\n\nTips:\n• Enter full name (First Last)\n• Check spelling\n• Class field is optional for system-wide search";
          _emptyStudentNameField = true;
          _studentNameErrorMessage = "Student not found";
        });
      }
    } catch (e) {
      setState(() {
        _showSpinner = false;
        _errorMessage = "Search failed. Please check your internet connection and try again.";
      });
      print('Parent login error: $e');
    }
  }

  Future<bool> _validateStudentInFirebase(String studentName, String studentClass) async {
    try {
      List<String> nameParts = studentName.toUpperCase().split(' ');
      if (nameParts.length < 2) {
        setState(() {
          _errorMessage = 'Please enter both first and last name (e.g., "John Doe")';
        });
        return false;
      }

      String firstName = nameParts[0];
      String lastName = nameParts[1];

      setState(() {
        _errorMessage = 'Searching for student...';
      });

      // Search through all schools and classes
      QuerySnapshot schoolsSnapshot = await _firestore.collection('Schools').get();

      for (QueryDocumentSnapshot schoolDoc in schoolsSnapshot.docs) {
        String schoolName = schoolDoc.id;

        // Get all classes in this school
        QuerySnapshot classesSnapshot = await _firestore
            .collection('Schools/$schoolName/Classes')
            .get();

        for (QueryDocumentSnapshot classDoc in classesSnapshot.docs) {
          String className = classDoc.id;

          // Skip if specific class was provided and this doesn't match
          if (studentClass.isNotEmpty && className.toUpperCase() != studentClass.toUpperCase()) {
            continue;
          }

          // Search students in this class
          bool found = await _searchStudentsInClass(schoolName, className, firstName, lastName, studentClass);
          if (found) return true;
        }
      }

      return false;

    } catch (e) {
      print('Error validating student: $e');
      setState(() {
        _errorMessage = 'Search failed due to network error. Please try again.';
      });
      return false;
    }
  }

  // Search students within a specific class
  Future<bool> _searchStudentsInClass(
      String schoolName,
      String className,
      String firstName,
      String lastName,
      String studentClass) async {
    try {
      String classPath = 'Schools/$schoolName/Classes/$className/Student_Details';

      QuerySnapshot studentsSnapshot = await _firestore.collection(classPath).get();

      for (QueryDocumentSnapshot studentDoc in studentsSnapshot.docs) {
        try {
          // Look directly in Personal_Information/Registered_Information
          DocumentSnapshot registeredInfoDoc = await _firestore
              .doc('$classPath/${studentDoc.id}/Personal_Information/Registered_Information')
              .get();

          if (registeredInfoDoc.exists) {
            Map<String, dynamic> data = registeredInfoDoc.data() as Map<String, dynamic>;

            String dbFirstName = data['firstName']?.toString().toUpperCase() ?? '';
            String dbLastName = data['lastName']?.toString().toUpperCase() ?? '';
            String dbClass = data['studentClass']?.toString().toUpperCase() ?? '';

            // Exact match for names
            bool nameMatch = (dbFirstName == firstName && dbLastName == lastName);
            bool classMatch = studentClass.isEmpty || (dbClass == studentClass.toUpperCase());

            if (nameMatch && classMatch) {
              // Save student data
              String fullName = '$firstName $lastName';

              ParentDataManager().setParentData(
                studentName: fullName,
                studentClass: studentClass.isEmpty ? className : studentClass,
                firstName: firstName,
                lastName: lastName,
                studentDetails: data,
              );

              await ParentDataManager().saveToPreferences();
              return true;
            }
          }
        } catch (e) {
          print('Error checking student ${studentDoc.id}: $e');
          continue;
        }
      }
      return false;
    } catch (e) {
      print('Class search error: $e');
      return false;
    }
  }


  void _handleFirebaseAuthException(FirebaseAuthException e) {
    setState(() {
      _showSpinner = false;
    });

    switch (e.code) {
      case 'user-not-found':
        setState(() {
          _emailNotRegistered = true;
          _emailErrorMessage = 'No account found with this email';
        });
        break;
      case 'wrong-password':
        setState(() {
          _wrongPassword = true;
          _passwordErrorMessage = 'Incorrect password';
        });
        break;
      case 'invalid-email':
        setState(() {
          _wrongEmail = true;
          _emailErrorMessage = 'Invalid email format';
        });
        break;
      case 'user-disabled':
        setState(() {
          _errorMessage = 'This account has been disabled';
        });
        break;
      case 'too-many-requests':
        setState(() {
          _errorMessage = 'Too many failed attempts. Please try again later';
        });
        break;
      case 'network-request-failed':
        setState(() {
          _errorMessage = 'Network error. Please check your connection';
        });
        break;
      default:
        setState(() {
          _errorMessage = 'Login failed. Please try again';
        });
        break;
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _showSpinner = false;
        });
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> _signInWithSocialMedia(String provider) async {
    setState(() {
      _showSpinner = true;
    });

    try {
      UserCredential? userCredential;

      if (provider == 'google') {
        userCredential = await _signInWithGoogle();
      } else if (provider == 'facebook') {
        userCredential = await _signInWithFacebook();
      }

      if (userCredential?.user != null) {
        // Fix 1: Use the correct route name or property
        // Replace 'Google_Done.id' with the actual route name
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home', // or whatever your actual route name is
              (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _showSpinner = false;
        _errorMessage = 'Social login failed. Please try again';
      });
      print('Social login error: $e');
    }
  }

  Future<UserCredential?> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Fix 2: Use 'tokenString' instead of 'token'
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(result.accessToken!.tokenString);

        return await _auth.signInWithCredential(facebookAuthCredential);
      } else {
        setState(() {
          _showSpinner = false;
        });
        return null;
      }
    } catch (e) {
      print('Facebook sign in error: $e');
      rethrow;
    }
  }

  Future<void> _checkExistingParentSession() async {
    try {
      await ParentDataManager().loadFromPreferences();

      if (ParentDataManager().studentName != null &&
          ParentDataManager().studentClass != null) {
        // Parent session exists, but don't auto-navigate
        // Let them choose mode manually
        setState(() {
          _isTeacherMode = false;
          studentName = ParentDataManager().studentName ?? '';
          studentClass = ParentDataManager().studentClass ?? '';
        });
      }
    } catch (e) {
      print('Error checking parent session: $e');
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
    });
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

  @override
  void dispose() {
    super.dispose();
  }
}