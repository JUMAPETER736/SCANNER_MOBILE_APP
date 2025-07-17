import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Student_Behavior extends StatefulWidget {
  final String schoolName;
  final String className;
  final String studentClass;
  final String studentName;

  const Student_Behavior({
    Key? key,
    required this.schoolName,
    required this.className,
    required this.studentClass,
    required this.studentName,
  }) : super(key: key);

  static String id = '/Student_Behavior';

  @override
  State<Student_Behavior> createState() => _Student_BehaviorState();
}

class _Student_BehaviorState extends State<Student_Behavior> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _behaviorData;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedTerm = 'TERM_ONE'; // Default term
  final List<String> _terms = ['TERM_ONE', 'TERM_TWO', 'TERM_THREE'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _fetchBehaviorData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getCurrentAcademicYear() {
    // Placeholder: Implement logic to get the current academic year
    // For example, "2025-2026" based on current date
    final now = DateTime.now();
    final year = now.month >= 7 ? now.year : now.year - 1;
    return '$year-${year + 1}';
  }

  Future<void> _fetchBehaviorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final behaviorData = await fetchStudentBehavior(
        schoolName: widget.schoolName,
        studentClass: widget.studentClass,
        studentFullName: widget.studentName,
        academicYear: _getCurrentAcademicYear(),
        term: _selectedTerm,
      );

      if (mounted) {
        setState(() {
          _behaviorData = behaviorData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching behavior data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> fetchStudentBehavior({
    required String schoolName,
    required String studentClass,
    required String studentFullName,
    required String academicYear,
    required String term,
  }) async {
    try {
      final DocumentSnapshot behaviorDoc = await _firestore
          .collection('Schools')
          .doc(schoolName)
          .collection('Classes')
          .doc(studentClass)
          .collection('Student_Details')
          .doc(studentFullName)
          .collection('Academic_Performance')
          .doc(academicYear)
          .collection(term)
          .doc('Term_Info')
          .collection('Student_Behavior')
          .doc('Behavior_Records')
          .get();

      if (behaviorDoc.exists) {
        return behaviorDoc.data() as Map<String, dynamic>;
      } else {
        print('Student behavior document does not exist for $term in $academicYear');
        return null;
      }
    } catch (e) {
      print('Error fetching student behavior: $e');
      return null;
    }
  }

  // Helper method to get responsive text size
  double getResponsiveTextSize(double baseSize, double screenWidth, double screenHeight) {
    double widthScale = screenWidth / 375;
    double heightScale = screenHeight / 667;
    double scale = (widthScale + heightScale) / 2;
    scale = scale.clamp(0.8, 2.0);
    return baseSize * scale;
  }

  // Helper method to get responsive padding/margin
  double getResponsiveSize(double baseSize, double screenWidth, double screenHeight) {
    double widthScale = screenWidth / 375;
    double heightScale = screenHeight / 667;
    double scale = (widthScale + heightScale) / 2;
    scale = scale.clamp(0.7, 1.8);
    return baseSize * scale;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Student Behavior',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: getResponsiveTextSize(18, screenWidth, screenHeight),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: EdgeInsets.all(getResponsiveSize(16, screenWidth, screenHeight)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Term selection dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: getResponsiveSize(12, screenWidth, screenHeight)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(getResponsiveSize(8, screenWidth, screenHeight)),
                  border: Border.all(color: Colors.blueAccent, width: 1),
                ),
                child: DropdownButton<String>(
                  value: _selectedTerm,
                  isExpanded: true,
                  hint: Text(
                    'Select Term',
                    style: TextStyle(
                      fontSize: getResponsiveTextSize(16, screenWidth, screenHeight),
                      color: Colors.grey,
                    ),
                  ),
                  items: _terms.map((String term) {
                    return DropdownMenuItem<String>(
                      value: term,
                      child: Text(
                        term.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: getResponsiveTextSize(16, screenWidth, screenHeight),
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTerm = newValue;
                        _fetchBehaviorData();
                      });
                    }
                  },
                ),
              ),
              SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
              Expanded(child: _buildBody(screenWidth, screenHeight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double screenWidth, double screenHeight) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(getResponsiveSize(16, screenWidth, screenHeight)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(getResponsiveSize(12, screenWidth, screenHeight)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: getResponsiveSize(10, screenWidth, screenHeight),
                offset: Offset(0, getResponsiveSize(2, screenWidth, screenHeight)),
              ),
            ],
          ),
          child: Text(
            _errorMessage!,
            style: TextStyle(
              color: const Color(0xFFDC2626),
              fontSize: getResponsiveTextSize(16, screenWidth, screenHeight),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_behaviorData == null) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(getResponsiveSize(16, screenWidth, screenHeight)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(getResponsiveSize(12, screenWidth, screenHeight)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: getResponsiveSize(10, screenWidth, screenHeight),
                offset: Offset(0, getResponsiveSize(2, screenWidth, screenHeight)),
              ),
            ],
          ),
          child: Text(
            'No behavior data found for this student in $_selectedTerm',
            style: TextStyle(
              fontSize: getResponsiveTextSize(16, screenWidth, screenHeight),
              color: const Color(0xFF667eea),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBehaviorCard('Conduct', _behaviorData!['conduct'] ?? 'N/A', screenWidth, screenHeight),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard('Class Participation', _behaviorData!['class_participation'] ?? 'N/A', screenWidth, screenHeight),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard('Punctuality', _behaviorData!['punctuality'] ?? 'N/A', screenWidth, screenHeight),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard(
            'Disciplinary Records',
            _behaviorData!['disciplinary_records']?.isEmpty ?? true
                ? 'No records'
                : (_behaviorData!['disciplinary_records'] as List).join(', '),
            screenWidth,
            screenHeight,
          ),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard('Behavior Notes', _behaviorData!['behavior_notes'] ?? 'N/A', screenWidth, screenHeight),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard(
            'Last Updated',
            _behaviorData!['last_updated'] != null
                ? (_behaviorData!['last_updated'] as Timestamp).toDate().toString()
                : 'N/A',
            screenWidth,
            screenHeight,
          ),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard(
            'Updated By',
            _behaviorData!['updated_by'] ?? 'N/A',
            screenWidth,
            screenHeight,
          ),
          SizedBox(height: getResponsiveSize(16, screenWidth, screenHeight)),
          _buildBehaviorCard(
            'Behavior Status',
            _behaviorData!['behavior_status'] ?? 'N/A',
            screenWidth,
            screenHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorCard(String title, String value, double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(getResponsiveSize(12, screenWidth, screenHeight)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: getResponsiveSize(10, screenWidth, screenHeight),
                    offset: Offset(0, getResponsiveSize(2, screenWidth, screenHeight)),
                  ),
                ],
              ),
              padding: EdgeInsets.all(getResponsiveSize(16, screenWidth, screenHeight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: getResponsiveTextSize(16, screenWidth, screenHeight),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF667eea),
                    ),
                  ),
                  SizedBox(height: getResponsiveSize(8, screenWidth, screenHeight)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: getResponsiveTextSize(14, screenWidth, screenHeight),
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}