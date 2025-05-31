import 'package:flutter/material.dart';

class Grade_Analytics extends StatelessWidget {
  final List<Map<String, String>> juniorGradeRanges = [
    {'range': '85 - 100%', 'grade': 'A', 'interpretation': 'EXCELLENT'},
    {'range': '75 - 84%', 'grade': 'B', 'interpretation': 'VERY GOOD'},
    {'range': '65 - 74%', 'grade': 'C', 'interpretation': 'GOOD'},
    {'range': '50 - 64%', 'grade': 'D', 'interpretation': 'PASS'},
    {'range': '0 - 49%', 'grade': 'F', 'interpretation': 'FAIL'},
  ];

  final List<Map<String, String>> seniorGradeRanges = [
    {'range': '100 - 90%', 'grade': '1', 'interpretation': 'DISTIONCTION'},
    {'range': '89 - 80%', 'grade': '2', 'interpretation': 'DISTIONCTION'},
    {'range': '79 - 75%', 'grade': '3', 'interpretation': 'STRONG CREDIT'},
    {'range': '74 - 70%', 'grade': '4', 'interpretation': 'CREDIT'},
    {'range': '69 - 65%', 'grade': '5', 'interpretation': 'WEAK CREDIT'},
    {'range': '64 - 60%', 'grade': '6', 'interpretation': 'SATISFACTORY PASS'},
    {'range': '59 - 55%', 'grade': '7', 'interpretation': 'PASS'},
    {'range': '54 - 50%', 'grade': '8', 'interpretation': 'WEAK PASS'},
    {'range': '0 - 49%', 'grade': '9', 'interpretation': 'FAIL'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Grade Format',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1976D2),
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1976D2).withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 28,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Grading System Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Junior Certificate Section
              _buildGradeSection(
                'Junior Certificate Education (JCE)',
                juniorGradeRanges,
                Color(0xFF1976D2),
              ),

              SizedBox(height: 20),

              // Senior Certificate Section
              _buildGradeSection(
                'Senior Certificate Education (MSCE)',
                seniorGradeRanges,
                Color(0xFF1565C0),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeSection(
      String title,
      List<Map<String, String>> grades,
      Color primaryColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),

        SizedBox(height: 8),

        // Grade List
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: grades.asMap().entries.map((entry) {
              Map<String, String> grade = entry.value;
              bool isLast = entry.key == grades.length - 1;

              return Container(
                decoration: BoxDecoration(
                  border: isLast ? null : Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Mark Range
                      Expanded(
                        flex: 2,
                        child: Text(
                          grade['range']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Grade
                      Container(
                        width: 30,
                        child: Text(
                          grade['grade']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(width: 16),

                      // Interpretation
                      Expanded(
                        flex: 2,
                        child: Text(
                          grade['interpretation']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}