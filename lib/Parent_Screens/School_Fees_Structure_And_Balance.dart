

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(SchoolFeesApp());
}

class SchoolFeesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Fees Management',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: SchoolFeesHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class School_Fees_Structure_And_Balance {
  final String studentId;
  final String studentName;
  final String grade;
  final String className;
  final Map<String, double> feeStructure;
  final Map<String, double> paidAmounts;
  final DateTime lastPaymentDate;
  final String parentContact;
  final String profileImage;

  School_Fees_Structure_And_Balance({
    required this.studentId,
    required this.studentName,
    required this.grade,
    required this.className,
    required this.feeStructure,
    required this.paidAmounts,
    required this.lastPaymentDate,
    required this.parentContact,
    this.profileImage = '',
  });

  double get totalFees => feeStructure.values.fold(0.0, (sum, amount) => sum + amount);

  double get totalPaid => paidAmounts.values.fold(0.0, (sum, amount) => sum + amount);

  double get outstandingBalance => totalFees - totalPaid;

  bool get isFullyPaid => outstandingBalance <= 0;

  Map<String, double> get feeBreakdown {
    Map<String, double> breakdown = {};
    feeStructure.forEach((feeType, amount) {
      double paid = paidAmounts[feeType] ?? 0.0;
      breakdown[feeType] = amount - paid;
    });
    return breakdown;
  }

  void makePayment(String feeType, double amount) {
    if (feeStructure.containsKey(feeType)) {
      paidAmounts[feeType] = (paidAmounts[feeType] ?? 0.0) + amount;
    }
  }

  double getProgressPercentage() {
    if (totalFees == 0) return 0.0;
    return (totalPaid / totalFees).clamp(0.0, 1.0);
  }

  String getPaymentStatus() {
    double percentage = getProgressPercentage();
    if (percentage >= 1.0) return 'Paid';
    if (percentage >= 0.8) return 'Almost Complete';
    if (percentage >= 0.5) return 'In Progress';
    return 'Pending';
  }

  Color getStatusColor() {
    double percentage = getProgressPercentage();
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.5) return Colors.blue;
    return Colors.red;
  }
}

class SchoolFeesHomePage extends StatefulWidget {
  @override
  _SchoolFeesHomePageState createState() => _SchoolFeesHomePageState();
}

class _SchoolFeesHomePageState extends State<SchoolFeesHomePage> with TickerProviderStateMixin {
  List<School_Fees_Structure_And_Balance> students = [];
  late AnimationController _fabController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeSampleData();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _initializeSampleData() {
    students = [
      School_Fees_Structure_And_Balance(
        studentId: "STU001",
        studentName: "John Doe",
        grade: "Grade 10",
        className: "10-A",
        parentContact: "+1234567890",
        feeStructure: {
          "Tuition Fee": 5000.0,
          "Laboratory Fee": 800.0,
          "Library Fee": 300.0,
          "Sports Fee": 500.0,
          "Transport Fee": 1200.0,
        },
        paidAmounts: {
          "Tuition Fee": 2500.0,
          "Laboratory Fee": 800.0,
          "Library Fee": 300.0,
        },
        lastPaymentDate: DateTime.now().subtract(Duration(days: 15)),
      ),
      School_Fees_Structure_And_Balance(
        studentId: "STU002",
        studentName: "Jane Smith",
        grade: "Grade 12",
        className: "12-B",
        parentContact: "+0987654321",
        feeStructure: {
          "Tuition Fee": 6000.0,
          "Laboratory Fee": 1000.0,
          "Library Fee": 400.0,
          "Sports Fee": 600.0,
          "Exam Fee": 300.0,
        },
        paidAmounts: {
          "Tuition Fee": 6000.0,
          "Laboratory Fee": 1000.0,
          "Library Fee": 400.0,
          "Sports Fee": 600.0,
          "Exam Fee": 300.0,
        },
        lastPaymentDate: DateTime.now().subtract(Duration(days: 5)),
      ),
      School_Fees_Structure_And_Balance(
        studentId: "STU003",
        studentName: "Mike Johnson",
        grade: "Grade 8",
        className: "8-C",
        parentContact: "+1122334455",
        feeStructure: {
          "Tuition Fee": 4500.0,
          "Laboratory Fee": 600.0,
          "Library Fee": 250.0,
          "Sports Fee": 400.0,
        },
        paidAmounts: {
          "Tuition Fee": 1500.0,
        },
        lastPaymentDate: DateTime.now().subtract(Duration(days: 30)),
      ),
    ];
  }

  List<School_Fees_Structure_And_Balance> get filteredStudents {
    if (searchQuery.isEmpty) return students;
    return students.where((student) {
      return student.studentName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          student.studentId.toLowerCase().contains(searchQuery.toLowerCase()) ||
          student.grade.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade600,
              Colors.purple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildStatsCards(),
              Expanded(child: _buildStudentsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddStudentDialog(),
          icon: Icon(Icons.person_add_rounded),
          label: Text('Add Student'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.indigo.shade700,
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.school_rounded, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Fees Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track and manage student payments',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    double totalRevenue = students.fold(0.0, (sum, student) => sum + student.totalPaid);
    double totalOutstanding = students.fold(0.0, (sum, student) => sum + student.outstandingBalance);
    int fullyPaidCount = students.where((student) => student.isFullyPaid).length;

    return Container(
      height: 120,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard(
            'Total Revenue',
            '\$${totalRevenue.toStringAsFixed(0)}',
            Icons.attach_money_rounded,
            Colors.green,
          ),
          _buildStatCard(
            'Outstanding',
            '\$${totalOutstanding.toStringAsFixed(0)}',
            Icons.pending_actions_rounded,
            Colors.orange,
          ),
          _buildStatCard(
            'Fully Paid',
            '$fullyPaidCount Students',
            Icons.check_circle_rounded,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    _fabController.forward();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: filteredStudents.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: filteredStudents.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeInOut,
            child: StudentFeeCard(
              student: filteredStudents[index],
              onPaymentMade: () => setState(() {}),
              onTap: () => _showStudentDetails(filteredStudents[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStudentDialog(
        onStudentAdded: (student) {
          setState(() {
            students.add(student);
          });
        },
      ),
    );
  }

  void _showStudentDetails(School_Fees_Structure_And_Balance student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsPage(
          student: student,
          onPaymentMade: () => setState(() {}),
        ),
      ),
    );
  }
}

class StudentFeeCard extends StatelessWidget {
  final School_Fees_Structure_And_Balance student;
  final VoidCallback onPaymentMade;
  final VoidCallback? onTap;

  const StudentFeeCard({
    Key? key,
    required this.student,
    required this.onPaymentMade,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: student.getStatusColor().withOpacity(0.1),
                      child: Text(
                        student.studentName.split(' ').map((n) => n[0]).take(2).join(),
                        style: TextStyle(
                          color: student.getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.studentName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.class_rounded, size: 16, color: Colors.grey.shade500),
                              SizedBox(width: 4),
                              Text(
                                '${student.grade} • ${student.className}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ID: ${student.studentId}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: student.getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        student.getPaymentStatus(),
                        style: TextStyle(
                          color: student.getStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Fees',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${student.totalFees.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${student.totalPaid.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Outstanding',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\$${student.outstandingBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: student.outstandingBalance > 0 ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: student.getProgressPercentage(),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(student.getStatusColor()),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${(student.getProgressPercentage() * 100).toStringAsFixed(1)}% Complete',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudentDetailsPage extends StatefulWidget {
  final School_Fees_Structure_And_Balance student;
  final VoidCallback onPaymentMade;

  const StudentDetailsPage({
    Key? key,
    required this.student,
    required this.onPaymentMade,
  }) : super(key: key);

  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Student Details'),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStudentHeader(),
            _buildPaymentSummary(),
            _buildFeeBreakdown(),
            _buildPaymentHistory(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentDialog(),
        icon: Icon(Icons.payment_rounded),
        label: Text('Make Payment'),
        backgroundColor: Colors.indigo.shade600,
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade600, Colors.purple.shade400],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              widget.student.studentName.split(' ').map((n) => n[0]).take(2).join(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            widget.student.studentName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${widget.student.grade} • ${widget.student.className}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ID: ${widget.student.studentId}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Fees',
                  '\$${widget.student.totalFees.toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Amount Paid',
                  '\$${widget.student.totalPaid.toStringAsFixed(0)}',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Outstanding',
                  '\$${widget.student.outstandingBalance.toStringAsFixed(0)}',
                  widget.student.outstandingBalance > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widget.student.getProgressPercentage(),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(widget.student.getStatusColor()),
              minHeight: 12,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${(widget.student.getProgressPercentage() * 100).toStringAsFixed(1)}% Complete',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            title == 'Total Fees' ? Icons.account_balance_wallet_rounded :
            title == 'Amount Paid' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeeBreakdown() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          ...widget.student.feeStructure.entries.map((entry) {
            double totalAmount = entry.value;
            double paidAmount = widget.student.paidAmounts[entry.key] ?? 0.0;
            double outstanding = totalAmount - paidAmount;
            double progress = totalAmount > 0 ? paidAmount / totalAmount : 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Text(
                        '\$${outstanding.toStringAsFixed(0)} / \$${totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: outstanding > 0
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        outstanding > 0 ? Colors.orange : Colors.green,
                      ),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% paid',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }


  Widget _buildPaymentHistory() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payment_rounded, color: Colors.green, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Payment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '${widget.student.lastPaymentDate.day}/${widget.student.lastPaymentDate.month}/${widget.student.lastPaymentDate.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${widget.student.totalPaid.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 16, color: Colors.grey.shade500),
              SizedBox(width: 8),
              Text(
                'Parent Contact: ${widget.student.parentContact}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        student: widget.student,
        onPaymentMade: () {
          widget.onPaymentMade();
          setState(() {});
        },
      ),
    );
  }
}

class AddStudentDialog extends StatefulWidget {
  final Function(School_Fees_Structure_And_Balance) onStudentAdded;

  const AddStudentDialog({Key? key, required this.onStudentAdded}) : super(key: key);

  @override
  _AddStudentDialogState createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _gradeController = TextEditingController();
  final _classController = TextEditingController();
  final _contactController = TextEditingController();

  Map<String, double> feeStructure = {
    'Tuition Fee': 0.0,
    'Laboratory Fee': 0.0,
    'Library Fee': 0.0,
    'Sports Fee': 0.0,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Student',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 24),
                _buildTextField(_nameController, 'Student Name', Icons.person_rounded),
                SizedBox(height: 16),
                _buildTextField(_idController, 'Student ID', Icons.badge_rounded),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(_gradeController, 'Grade', Icons.school_rounded),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(_classController, 'Class', Icons.class_rounded),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildTextField(_contactController, 'Parent Contact', Icons.phone_rounded),
                SizedBox(height: 24),
                Text(
                  'Fee Structure',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),
                ...feeStructure.keys.map((feeType) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: feeType,
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: (value) {
                        feeStructure[feeType] = double.tryParse(value) ?? 0.0;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter valid number';
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _addStudent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Add Student'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  void _addStudent() {
    if (_formKey.currentState!.validate()) {
      final student = School_Fees_Structure_And_Balance(
        studentId: _idController.text,
        studentName: _nameController.text,
        grade: _gradeController.text,
        className: _classController.text,
        parentContact: _contactController.text,
        feeStructure: Map.from(feeStructure),
        paidAmounts: {},
        lastPaymentDate: DateTime.now(),
      );

      widget.onStudentAdded(student);
      Navigator.pop(context);
    }
  }
}

class PaymentDialog extends StatefulWidget {
  final School_Fees_Structure_And_Balance student;
  final VoidCallback onPaymentMade;

  const PaymentDialog({
    Key? key,
    required this.student,
    required this.onPaymentMade,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String? selectedFeeType;
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    List<String> availableFeeTypes = widget.student.feeStructure.keys
        .where((feeType) {
      double total = widget.student.feeStructure[feeType] ?? 0.0;
      double paid = widget.student.paidAmounts[feeType] ?? 0.0;
      return paid < total;
    })
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Make Payment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'for ${widget.student.studentName}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedFeeType,
                decoration: InputDecoration(
                  labelText: 'Select Fee Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: availableFeeTypes.map((feeType) {
                  double total = widget.student.feeStructure[feeType] ?? 0.0;
                  double paid = widget.student.paidAmounts[feeType] ?? 0.0;
                  double outstanding = total - paid;

                  return DropdownMenuItem(
                    value: feeType,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(feeType),
                        Text(
                          'Outstanding: \$${outstanding.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFeeType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select fee type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }

                  double? amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }

                  if (selectedFeeType != null) {
                    double total = widget.student.feeStructure[selectedFeeType!] ?? 0.0;
                    double paid = widget.student.paidAmounts[selectedFeeType!] ?? 0.0;
                    double outstanding = total - paid;

                    if (amount > outstanding) {
                      return 'Amount exceeds outstanding balance';
                    }
                  }

                  return null;
                },
              ),
              if (selectedFeeType != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Fee:'),
                          Text('\$${widget.student.feeStructure[selectedFeeType!]!.toStringAsFixed(0)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Already Paid:'),
                          Text('\$${(widget.student.paidAmounts[selectedFeeType!] ?? 0.0).toStringAsFixed(0)}'),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Outstanding:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${(widget.student.feeStructure[selectedFeeType!]! - (widget.student.paidAmounts[selectedFeeType!] ?? 0.0)).toStringAsFixed(0)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: availableFeeTypes.isEmpty ? null : _makePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Make Payment'),
                    ),
                  ),
                ],
              ),
              if (availableFeeTypes.isEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All fees have been paid for this student!',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
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

  void _makePayment() {
    if (_formKey.currentState!.validate() && selectedFeeType != null) {
      double amount = double.parse(_amountController.text);
      widget.student.makePayment(selectedFeeType!, amount);

      widget.onPaymentMade();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of \$${amount.toStringAsFixed(0)} made successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}