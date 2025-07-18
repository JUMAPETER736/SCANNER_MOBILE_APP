import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../School_Report/Juniors_Class_Performance.dart';
import '../School_Report/Seniors_Class_Performance.dart';

class Performance_Statistics extends StatefulWidget {
  const Performance_Statistics({Key? key}) : super(key: key);

  @override
  State<Performance_Statistics> createState() => _Performance_StatisticsState();
}

class _Performance_StatisticsState extends State<Performance_Statistics>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _errorMessage = '';
  String _loadingStep = 'Initializing...';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Cache for user data to avoid repeated fetches
  static String? _cachedSchoolName;
  static String? _cachedClassName;
  static String? _cachedUserEmail;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAndNavigate();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Faster animation
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster progress
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Faster curve
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _progressController.repeat();
  }

  Future<void> _checkAndNavigate() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("Please log in to continue");
      }

      // Check cache first for instant loading
      if (_cachedUserEmail == currentUser.email &&
          _cachedSchoolName != null &&
          _cachedClassName != null) {
        // Navigate immediately with cached data
        _navigateToClassPage(_cachedSchoolName!, _cachedClassName!);
        return;
      }

      _updateLoadingStep('Loading...');

      // Ultra-fast Firebase query with timeout and cache priority
      final teacherDoc = _firestore
          .collection('Teachers_Details')
          .doc(currentUser.email);

      // Try cache first, then server with aggressive timeout
      DocumentSnapshot? teacherSnapshot;

      try {
        // First attempt: Cache only (instant)
        teacherSnapshot = await teacherDoc.get(
            const GetOptions(source: Source.cache)
        ).timeout(const Duration(milliseconds: 100));
      } catch (_) {
        // Second attempt: Server with aggressive timeout
        teacherSnapshot = await teacherDoc.get(
            const GetOptions(source: Source.server)
        ).timeout(const Duration(seconds: 3));
      }

      if (!teacherSnapshot.exists) {
        throw Exception("Teacher profile not found. Please contact admin.");
      }

      final data = teacherSnapshot.data() as Map<String, dynamic>;
      final String schoolName = (data['school'] ?? '').toString().trim();
      final List<dynamic>? classList = data['classes'];
      final String className = (classList != null && classList.isNotEmpty)
          ? classList[0].toString().trim()
          : '';

      if (schoolName.isEmpty || className.isEmpty) {
        throw Exception("Incomplete profile data. Please update your profile.");
      }

      // Cache the data for instant future access
      _cachedUserEmail = currentUser.email;
      _cachedSchoolName = schoolName;
      _cachedClassName = className;

      // Navigate immediately without delays
      _navigateToClassPage(schoolName, className);

    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _updateLoadingStep(String step) {
    if (mounted) {
      setState(() {
        _loadingStep = step;
      });
    }
  }

  void _navigateToClassPage(String schoolName, String className) {
    if (!mounted) return;

    late Widget targetPage;

    if (className == 'FORM 1' || className == 'FORM 2') {
      targetPage = Juniors_Class_Performance(
        schoolName: schoolName,
        className: className,
      );
    } else if (className == 'FORM 3' || className == 'FORM 4') {
      targetPage = Seniors_Class_Performance(
        schoolName: schoolName,
        className: className,
      );
    } else {
      _handleError("Unsupported class: $className. Please contact support.");
      return;
    }

    // Instant navigation without animation delays
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150), // Much faster
      ),
    );
  }

  void _handleError(String error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _loadingStep = 'Retrying...';
    });
    _checkAndNavigate();
  }

  void _clearCache() {
    _cachedUserEmail = null;
    _cachedSchoolName = null;
    _cachedClassName = null;
    _retry();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Performance Analytics',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,

          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF6B7280)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: _buildBody(),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) ...[
            _buildLoadingContent(),
          ] else ...[
            _buildErrorContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        const CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 32),
        Text(
          _loadingStep,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Setting up your performance dashboard',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: 50,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Connection Issue',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            _buildActionButton(
              onPressed: _clearCache,
              icon: Icons.clear_all,
              label: 'Clear Cache',
              isPrimary: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF3B82F6) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF6B7280),
        elevation: isPrimary ? 2 : 0,
        side: isPrimary ? null : BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}