import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Log_In_And_Register_Screens/Login_Page.dart';

class School_Fees_Structure_And_Balance extends StatefulWidget {
  static const String id = 'school_fees_structure_and_balance';

  const School_Fees_Structure_And_Balance({
    Key? key,
    required String schoolName,
    required String studentClass,
    required String studentName,
  }) : super(key: key);

  @override
  _School_Fees_Structure_And_BalanceState createState() => _School_Fees_Structure_And_BalanceState();
}

class _School_Fees_Structure_And_BalanceState extends State<School_Fees_Structure_And_Balance> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _schoolName;
  String? _studentName;
  String? _studentClass;
  bool _isLoading = true;
  Map<String, dynamic>? _feesData;
  Map<String, dynamic>? _schoolData; // Added for school information
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      // Load data from ParentDataManager
      await ParentDataManager().loadFromPreferences();

      setState(() {
        _schoolName = ParentDataManager().schoolName;
        _studentName = ParentDataManager().studentName;
        _studentClass = ParentDataManager().studentClass;
      });

      print('🏫 Parent Data Loaded:');
      print('School: $_schoolName');
      print('Student: $_studentName');
      print('Class: $_studentClass');

      // Load both fees data and school information
      await Future.wait([
        _loadFeesData(),
        _loadSchoolData(),
      ]);
    } catch (e) {
      print('❌ Error loading parent data: $e');
      setState(() {
        _errorMessage = 'Error loading parent data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFeesData() async {
    if (_schoolName == null || _schoolName!.isEmpty) {
      setState(() {
        _errorMessage = 'School name not available';
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch fees details from Firestore
      final DocumentSnapshot feesSnapshot = await _firestore
          .collection('Schools')
          .doc(_schoolName!)
          .collection('School_Information')
          .doc('Fees_Details')
          .get();

      if (feesSnapshot.exists) {
        setState(() {
          _feesData = feesSnapshot.data() as Map<String, dynamic>?;
        });
        print('💰 Fees data loaded successfully');
        print('Fees data: $_feesData');
      } else {
        print('⚠️ No fees document found');
        // Create default fees structure if it doesn't exist
        await _createDefaultFeesStructure();
      }
    } catch (e) {
      print('❌ Error loading fees data: $e');
      setState(() {
        _errorMessage = 'Error loading fees data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSchoolData() async {
    if (_schoolName == null || _schoolName!.isEmpty) {
      return;
    }

    try {
      // Fetch school details from Firestore
      final DocumentSnapshot schoolSnapshot = await _firestore
          .collection('Schools')
          .doc(_schoolName!)
          .collection('School_Information')
          .doc('School_Details')
          .get();

      if (schoolSnapshot.exists) {
        setState(() {
          _schoolData = schoolSnapshot.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
        print('🏫 School data loaded successfully');
        print('School data: $_schoolData');
      } else {
        setState(() {
          _isLoading = false;
        });
        print('⚠️ No school details document found');
      }
    } catch (e) {
      print('❌ Error loading school data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultFeesStructure() async {
    try {
      final DocumentReference feesDetailsRef = _firestore
          .collection('Schools')
          .doc(_schoolName!)
          .collection('School_Information')
          .doc('Fees_Details');

      final defaultFeesData = {
        'tuition_fee': 0,
        'development_fee': 0,
        'library_fee': 0,
        'sports_fee': 0,
        'laboratory_fee': 0,
        'other_fees': 0,
        'total_fees': 0,
        'bank_account_number': 'Not Set',
        'mobile_money_number': 'Not Set',
        'cash_payment_location': 'Not Set',
        'amount_paid': 0,
        'outstanding_balance': 0,
        'next_payment_due': 'Not Set',
        'bank_name': 'Not Set',
        'bank_account_name': 'Not Set',
        'airtel_money': 'Not Set',
        'tnm_mpamba': 'Not Set',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await feesDetailsRef.set(defaultFeesData);

      setState(() {
        _feesData = defaultFeesData;
      });

      print('✅ Default fees structure created');
    } catch (e) {
      print('❌ Error creating default fees structure: $e');
    }
  }

  // Helper method to safely get string value
  String _getStringValue(dynamic value) {
    if (value == null) return 'Not Available';
    if (value is String && value.isEmpty) return 'Not Set';
    if (value is String && (value.toLowerCase() == 'n/a' || value.toLowerCase() == 'not available')) return 'Not Set';
    return value.toString();
  }

  // Helper method to safely get numeric value
  String _getNumericValue(dynamic value) {
    if (value == null) return '0';
    if (value is num) return value.toString();
    if (value is String) {
      try {
        return double.parse(value).toString();
      } catch (e) {
        return '0';
      }
    }
    return '0';
  }

  // Helper method to get responsive dimensions
  double _getResponsiveValue(BuildContext context, double mobile, double tablet, double desktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return mobile;
    } else if (screenWidth < 1200) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Helper method to check if screen is small
  bool _isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = _isSmallScreen(context);

    // Loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('School Fees'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              SizedBox(height: 16),
              Text(
                'Loading fees information...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('School Fees'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(_getResponsiveValue(context, 16, 24, 32)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: _getResponsiveValue(context, 60, 80, 100),
                  color: Colors.red,
                ),
                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                Text(
                  'Error Loading Fees Data',
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 18, 22, 26),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: _getResponsiveValue(context, 8, 12, 16)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveValue(context, 16, 32, 48),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: _getResponsiveValue(context, 14, 16, 18),
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadParentData();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveValue(context, 16, 20, 24),
                      vertical: _getResponsiveValue(context, 8, 10, 12),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: _getResponsiveValue(context, 14, 16, 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main content
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Fees',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: _getResponsiveValue(context, 18, 20, 22),
              ),
            ),
            if (!isSmall && _schoolName != null)
              Text(
                _schoolName!,
                style: TextStyle(
                  fontSize: _getResponsiveValue(context, 14, 16, 18),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            iconSize: _getResponsiveValue(context, 24, 28, 32),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadParentData();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadParentData,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(_getResponsiveValue(context, 16, 20, 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Info Card
                if (_studentName != null && _studentClass != null)
                  _buildStudentInfoCard(),
                if (_studentName != null && _studentClass != null)
                  SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),

                // Fees Structure Card
                _buildFeesStructureCard(),
                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),

                // Payment Methods Card
                _buildPaymentMethodsCard(),
                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),

                // Balance Information Card
                _buildBalanceCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      elevation: _getResponsiveValue(context, 4, 6, 8),
      shadowColor: Colors.blue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveValue(context, 16, 20, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getResponsiveValue(context, 8, 10, 12)),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: _getResponsiveValue(context, 20, 24, 28),
                    ),
                  ),
                  SizedBox(width: _getResponsiveValue(context, 12, 16, 20)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentName ?? 'Unknown Student',
                          style: TextStyle(
                            fontSize: _getResponsiveValue(context, 18, 20, 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Class: ${_studentClass ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: _getResponsiveValue(context, 14, 16, 18),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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

  Widget _buildFeesStructureCard() {
    return Card(
      elevation: _getResponsiveValue(context, 4, 6, 8),
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveValue(context, 16, 20, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getResponsiveValue(context, 8, 10, 12)),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: _getResponsiveValue(context, 20, 24, 28),
                    ),
                  ),
                  SizedBox(width: _getResponsiveValue(context, 12, 16, 20)),
                  Expanded(
                    child: Text(
                      'Fees Structure',
                      style: TextStyle(
                        fontSize: _getResponsiveValue(context, 18, 20, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
              if (_feesData != null) ...[
                _buildFeeItem('Tuition Fee', _feesData!['tuition_fee']),
                _buildFeeItem('Development Fee', _feesData!['development_fee']),
                _buildFeeItem('Library Fee', _feesData!['library_fee']),
                _buildFeeItem('Sports Fee', _feesData!['sports_fee']),
                _buildFeeItem('Laboratory Fee', _feesData!['laboratory_fee']),
                _buildFeeItem('Other Fees', _feesData!['other_fees']),
                Divider(thickness: 2),
                _buildFeeItem('Total Fees', _feesData!['total_fees'], isTotal: true),
              ] else
                Text(
                  'No fees structure available',
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      elevation: _getResponsiveValue(context, 4, 6, 8),
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveValue(context, 16, 20, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getResponsiveValue(context, 8, 10, 12)),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                    ),
                    child: Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: _getResponsiveValue(context, 20, 24, 28),
                    ),
                  ),
                  SizedBox(width: _getResponsiveValue(context, 12, 16, 20)),
                  Expanded(
                    child: Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: _getResponsiveValue(context, 18, 20, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
              if (_feesData != null) ...[
                // Bank Transfer Section
                _buildPaymentSectionHeader('BANK TRANSFER', Icons.account_balance),
                _buildPaymentMethod('Bank Name', _getStringValue(_feesData!['bank_name'])),
                _buildPaymentMethod('Account Name', _getStringValue(_feesData!['bank_account_name'])),
                _buildPaymentMethod('Account Number', _getStringValue(_feesData!['bank_account_number'])),

                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),

                // Mobile Money Section
                _buildPaymentSectionHeader('MOBILE MONEY', Icons.phone_android),
                _buildPaymentMethod('Airtel Money', _getStringValue(_feesData!['airtel_money'])),
                _buildPaymentMethod('TNM Mpamba', _getStringValue(_feesData!['tnm_mpamba'])),

                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),

                // Other Payment Methods
                _buildPaymentSectionHeader('OTHER METHODS', Icons.location_on),
                _buildPaymentMethod('Cash Payment Location', _getStringValue(_feesData!['cash_payment_location'])),
              ] else ...[
                Container(
                  padding: EdgeInsets.all(_getResponsiveValue(context, 16, 20, 24)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: _getResponsiveValue(context, 40, 50, 60),
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(height: _getResponsiveValue(context, 8, 10, 12)),
                      Text(
                        'No payment methods configured',
                        style: TextStyle(
                          fontSize: _getResponsiveValue(context, 14, 16, 18),
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Please contact school administration',
                        style: TextStyle(
                          fontSize: _getResponsiveValue(context, 12, 14, 16),
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: _getResponsiveValue(context, 4, 6, 8),
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(_getResponsiveValue(context, 16, 20, 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_getResponsiveValue(context, 8, 10, 12)),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: _getResponsiveValue(context, 20, 24, 28),
                    ),
                  ),
                  SizedBox(width: _getResponsiveValue(context, 12, 16, 20)),
                  Expanded(
                    child: Text(
                      'Balance Information',
                      style: TextStyle(
                        fontSize: _getResponsiveValue(context, 18, 20, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
              if (_feesData != null) ...[
                _buildBalanceItem('Amount Paid', _getNumericValue(_feesData!['amount_paid']), Colors.green),
                _buildBalanceItem('Outstanding Balance', _getNumericValue(_feesData!['outstanding_balance']), Colors.red),
                _buildBalanceItem('Next Payment Due', _getStringValue(_feesData!['next_payment_due']), Colors.orange, isDate: true),
              ] else
                Text(
                  'No balance information available',
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeItem(String label, dynamic amount, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsiveValue(context, 4, 6, 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _getResponsiveValue(context, 14, 16, 18),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green.shade700 : Colors.black87,
            ),
          ),
          Text(
            'MWK ${_getNumericValue(amount)}',
            style: TextStyle(
              fontSize: _getResponsiveValue(context, 14, 16, 18),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: _getResponsiveValue(context, 8, 10, 12)),
      child: Row(
        children: [
          Icon(
            icon,
            size: _getResponsiveValue(context, 16, 18, 20),
            color: Colors.blueAccent,
          ),
          SizedBox(width: _getResponsiveValue(context, 8, 10, 12)),
          Text(
            title,
            style: TextStyle(
              fontSize: _getResponsiveValue(context, 14, 16, 18),
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String label, String value) {
    bool isAvailable = value != 'Not Available' && value != 'Not Set' && value.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsiveValue(context, 4, 6, 8)),
      child: Container(
        padding: EdgeInsets.all(_getResponsiveValue(context, 12, 14, 16)),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
          border: Border.all(
            color: isAvailable ? Colors.green.shade200 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.info,
              size: _getResponsiveValue(context, 16, 18, 20),
              color: isAvailable ? Colors.green.shade600 : Colors.grey.shade500,
            ),
            SizedBox(width: _getResponsiveValue(context, 8, 12, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: _getResponsiveValue(context, 14, 16, 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: _getResponsiveValue(context, 13, 15, 17),
                      fontWeight: FontWeight.w500,
                      color: isAvailable ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String amount, Color color, {bool isDate = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsiveValue(context, 6, 8, 10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _getResponsiveValue(context, 14, 16, 18),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveValue(context, 8, 10, 12),
              vertical: _getResponsiveValue(context, 4, 6, 8),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_getResponsiveValue(context, 6, 8, 10)),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              isDate ? amount : 'MWK $amount',
              style: TextStyle(
                fontSize: _getResponsiveValue(context, 14, 16, 18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ParentDataManager class that seems to be missing
class ParentDataManager {
  static final ParentDataManager _instance = ParentDataManager._internal();
  factory ParentDataManager() => _instance;
  ParentDataManager._internal();

  String? schoolName;
  String? studentName;
  String? studentClass;

  Future<void> loadFromPreferences() async {
    // Add your SharedPreferences loading logic here
    // This is a placeholder implementation
    try {
      // Example implementation - replace with your actual logic
      schoolName = "Sample School"; // Load from SharedPreferences
      studentName = "Sample Student"; // Load from SharedPreferences
      studentClass = "Grade 10"; // Load from SharedPreferences
    } catch (e) {
      print('Error loading preferences: $e');
      throw e;
    }
  }
}