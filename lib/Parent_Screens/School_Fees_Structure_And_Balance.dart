

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
    required String studentName
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


      // Load fees data after parent data is loaded
      await _loadFeesData();
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
          _isLoading = false;
          _errorMessage = null;
        });
        print('💰 Fees data loaded successfully');
      } else {
        setState(() {
          _errorMessage = 'No fees information found for this school';
          _isLoading = false;
        });
        print('⚠️ No fees document found');
      }
    } catch (e) {
      print('❌ Error loading fees data: $e');
      setState(() {
        _errorMessage = 'Error loading fees data: $e';
        _isLoading = false;
      });
    }
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
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('School Fees'),
          backgroundColor: Colors.green,
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
            colors: [Colors.green, Colors.white],
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
                // Student Information Card
                _buildStudentInfoCard(),
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
                      color: Colors.green,
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
                    child: Text(
                      'Student Information',
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
              _buildInfoRow('Student Name', _studentName ?? 'N/A', Icons.person_outline),
              _buildInfoRow('Class', _studentClass ?? 'N/A', Icons.class_),
              _buildInfoRow('School', _schoolName ?? 'N/A', Icons.school),
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
                      color: Colors.green,
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
                      color: Colors.green,
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
                _buildPaymentMethod('Bank Transfer', _feesData!['bank_account_number'], Icons.account_balance),
                _buildPaymentMethod('Mobile Money', _feesData!['mobile_money_number'], Icons.phone_android),
                _buildPaymentMethod('Cash Payment', _feesData!['cash_payment_location'], Icons.money),
              ] else
                Text(
                  'No payment methods available',
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
                      color: Colors.green,
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
                _buildBalanceItem('Amount Paid', _feesData!['amount_paid'], Colors.green),
                _buildBalanceItem('Outstanding Balance', _feesData!['outstanding_balance'], Colors.red),
                _buildBalanceItem('Next Payment Due', _feesData!['next_payment_due'], Colors.orange),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsiveValue(context, 6, 8, 10)),
      child: Row(
        children: [
          Icon(
            icon,
            size: _getResponsiveValue(context, 18, 20, 24),
            color: Colors.green,
          ),
          SizedBox(width: _getResponsiveValue(context, 8, 12, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 12, 14, 16),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            amount != null ? 'MWK ${amount.toString()}' : 'N/A',
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

  Widget _buildPaymentMethod(String method, dynamic details, IconData icon) {
    if (details == null || details.toString().isEmpty) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: _getResponsiveValue(context, 6, 8, 10)),
      child: Row(
        children: [
          Icon(
            icon,
            size: _getResponsiveValue(context, 18, 20, 24),
            color: Colors.green,
          ),
          SizedBox(width: _getResponsiveValue(context, 8, 12, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  details.toString(),
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 12, 14, 16),
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, dynamic amount, Color color) {
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
            ),
            child: Text(
              amount != null ? 'MWK ${amount.toString()}' : 'N/A',
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