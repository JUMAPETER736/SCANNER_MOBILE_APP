import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class Create_Upcoming_School_Event extends StatefulWidget {
  final String schoolName;
  final String selectedClass;

  const Create_Upcoming_School_Event({
    Key? key,
    required this.schoolName,
    required this.selectedClass,
  }) : super(key: key);

  @override
  _Create_Upcoming_School_EventState createState() => _Create_Upcoming_School_EventState();
}

class _Create_Upcoming_School_EventState extends State<Create_Upcoming_School_Event> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _teacherSchool;

  double getResponsiveTextSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate diagonal screen size for better device detection
    double diagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);

    // Device type detection
    bool isTablet = diagonal > 1100; // Tablets typically have diagonal > 1100
    bool isLargePhone = screenWidth > 400 && screenWidth < 600;
    bool isSmallPhone = screenWidth <= 400;

    double scaleFactor;

    if (isTablet) {
      // For tablets: more conservative scaling to prevent oversized text
      scaleFactor = (screenWidth / 768.0) * 0.85; // 768 is iPad baseline, reduced by 15%
      scaleFactor = scaleFactor.clamp(0.9, 1.4); // Limit tablet scaling between 90% and 140%
    } else if (isLargePhone) {
      // For large phones: moderate scaling
      scaleFactor = screenWidth / 414.0; // iPhone 6 Plus baseline
      scaleFactor = scaleFactor.clamp(0.8, 1.2); // Limit scaling between 80% and 120%
    } else {
      // For regular/small phones: more aggressive scaling
      scaleFactor = screenWidth / 375.0; // iPhone 6/7/8 baseline
      scaleFactor = scaleFactor.clamp(0.7, 1.3); // Allow wider range for small devices
    }

    return baseSize * scaleFactor;
  }

  double getResponsiveTextSizeByCategory(BuildContext context, double baseSize, String category) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double diagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);

    bool isTablet = diagonal > 1100;
    bool isLargePhone = screenWidth > 400 && screenWidth < 600;

    double scaleFactor;

    // Category-specific scaling adjustments
    double categoryMultiplier = 1.0;
    switch (category.toLowerCase()) {
      case 'title':
      case 'heading':
        categoryMultiplier = isTablet ? 0.9 : 1.0; // Slightly smaller titles on tablets
        break;
      case 'body':
      case 'content':
        categoryMultiplier = isTablet ? 0.95 : 1.0; // Slightly smaller body text on tablets
        break;
      case 'caption':
      case 'small':
        categoryMultiplier = isTablet ? 1.0 : 1.0; // Keep small text consistent
        break;
      case 'button':
        categoryMultiplier = isTablet ? 0.9 : 1.0; // Slightly smaller button text on tablets
        break;
      default:
        categoryMultiplier = 1.0;
    }

    if (isTablet) {
      scaleFactor = (screenWidth / 768.0) * 0.85 * categoryMultiplier;
      scaleFactor = scaleFactor.clamp(0.9, 1.4);
    } else if (isLargePhone) {
      scaleFactor = (screenWidth / 414.0) * categoryMultiplier;
      scaleFactor = scaleFactor.clamp(0.8, 1.2);
    } else {
      scaleFactor = (screenWidth / 375.0) * categoryMultiplier;
      scaleFactor = scaleFactor.clamp(0.7, 1.3);
    }

    return baseSize * scaleFactor;
  }

  @override
  void initState() {
    super.initState();
    _getTeacherSchool();
  }

  Future<void> _getTeacherSchool() async {
    try {
      String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      if (currentUserEmail != null) {
        DocumentSnapshot teacherDoc = await _firestore
            .collection('Teachers_Details')
            .doc(currentUserEmail)
            .get();

        if (teacherDoc.exists) {
          Map<String, dynamic> teacherData = teacherDoc.data() as Map<String, dynamic>;
          setState(() {
            _teacherSchool = teacherData['school'];
          });
        }
      }
    } catch (e) {
      print('Error fetching teacher school: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String actualSchool = _teacherSchool ?? widget.schoolName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Events - $actualSchool',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: getResponsiveTextSizeByCategory(context, 18, 'title'),
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Schools')
              .doc(actualSchool)
              .collection('Upcoming_School_Events')
              .where('dateTime', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(Duration(days: 7))))
              .orderBy('dateTime', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        Icons.error_outline,
                        size: getResponsiveTextSizeByCategory(context, 60, 'title'),
                        color: Colors.red
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading events',
                      style: TextStyle(
                          fontSize: getResponsiveTextSizeByCategory(context, 18, 'heading'),
                          color: Colors.red
                      ),
                    ),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                          fontSize: getResponsiveTextSizeByCategory(context, 12, 'small'),
                          color: Colors.grey
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: getResponsiveTextSizeByCategory(context, 80, 'title'),
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Events Yet',
                      style: TextStyle(
                        fontSize: getResponsiveTextSizeByCategory(context, 24, 'heading'),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first event for $actualSchool',
                      style: TextStyle(
                        fontSize: getResponsiveTextSizeByCategory(context, 16, 'body'),
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final eventDateTime = (data['dateTime'] as Timestamp).toDate();
                  final now = DateTime.now();
                  final isUpcoming = eventDateTime.isAfter(now);
                  final relativeDate = _getRelativeDate(eventDateTime);
                  final shouldShow = eventDateTime.isAfter(DateTime.now().subtract(Duration(days: 7)));

                  if (!shouldShow) return SizedBox.shrink();

                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 8,
                      shadowColor: Colors.blueAccent.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: isUpcoming
                                ? [Colors.white, Colors.blue.shade50]
                                : [Colors.grey.shade100, Colors.grey.shade200],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isUpcoming ? Colors.blueAccent : Colors.grey,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getEventIcon(data['type']),
                                      color: Colors.white,
                                      size: getResponsiveTextSizeByCategory(context, 20, 'body'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? 'No Title',
                                          style: TextStyle(
                                            fontSize: getResponsiveTextSizeByCategory(context, 18, 'title'),
                                            fontWeight: FontWeight.bold,
                                            color: isUpcoming ? Colors.black87 : Colors.grey.shade600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isUpcoming
                                                ? Colors.blueAccent.shade100
                                                : Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            data['type'] ?? 'Event',
                                            style: TextStyle(
                                              fontSize: getResponsiveTextSizeByCategory(context, 12, 'small'),
                                              fontWeight: FontWeight.w500,
                                              color: isUpcoming ? Colors.blue.shade700 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isUpcoming)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Past',
                                        style: TextStyle(
                                          fontSize: getResponsiveTextSizeByCategory(context, 10, 'small'),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                data['description'] ?? 'No description',
                                style: TextStyle(
                                  fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        Icons.calendar_today,
                                        size: getResponsiveTextSizeByCategory(context, 16, 'body'),
                                        color: Colors.blueAccent
                                    ),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}',
                                          style: TextStyle(
                                            fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (relativeDate.isNotEmpty)
                                          Text(
                                            relativeDate,
                                            style: TextStyle(
                                              fontSize: getResponsiveTextSizeByCategory(context, 12, 'small'),
                                              fontWeight: FontWeight.bold,
                                              color: isUpcoming ? Colors.green.shade600 : Colors.orange.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 16),
                                    Icon(
                                        Icons.access_time,
                                        size: getResponsiveTextSizeByCategory(context, 16, 'body'),
                                        color: Colors.blueAccent
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      TimeOfDay.fromDateTime(eventDateTime).format(context),
                                      style: TextStyle(
                                        fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                      Icons.location_on,
                                      size: getResponsiveTextSizeByCategory(context, 16, 'body'),
                                      color: Colors.grey.shade600
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data['location'] ?? 'No location',
                                      style: TextStyle(
                                        fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showEventDetails(context, data),
                                    child: Text(
                                      'View Details',
                                      style: TextStyle(
                                        fontSize: getResponsiveTextSizeByCategory(context, 14, 'button'),
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEventDialog(context),
        backgroundColor: Colors.blueAccent,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Event',
          style: TextStyle(
            fontSize: getResponsiveTextSizeByCategory(context, 16, 'button'),
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 8,
      ),
    );
  }

  IconData _getEventIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'academic':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'cultural':
        return Icons.theater_comedy;
      case 'meeting':
        return Icons.groups;
      case 'examination':
        return Icons.quiz;
      case 'holiday':
        return Icons.celebration;
      default:
        return Icons.event;
    }
  }

  String _getRelativeDate(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = eventDay.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      return '$difference days remaining';
    } else if (difference < -1 && difference >= -7) {
      return '${difference.abs()} days ago';
    } else if (difference > 7) {
      return 'In ${difference} days';
    } else {
      return '';
    }
  }

  void _showCreateEventDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventPage(
          schoolName: _teacherSchool ?? widget.schoolName,
          selectedClass: widget.selectedClass,
        ),
      ),
    );
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> data) {
    final eventDateTime = (data['dateTime'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                _getEventIcon(data['type']),
                color: Colors.blueAccent,
                size: getResponsiveTextSizeByCategory(context, 24, 'title'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['title'] ?? 'Event Details',
                  style: TextStyle(
                    fontSize: getResponsiveTextSizeByCategory(context, 20, 'title'),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', data['type'] ?? 'N/A', Icons.category),
                _buildDetailRow('Description', data['description'] ?? 'N/A', Icons.description),
                _buildDetailRow('Location', data['location'] ?? 'N/A', Icons.location_on),
                _buildDetailRow('Date', '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}', Icons.calendar_today),
                _buildDetailRow('Time', TimeOfDay.fromDateTime(eventDateTime).format(context), Icons.access_time),
                _buildDetailRow('School', data['schoolName'] ?? 'N/A', Icons.school),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: getResponsiveTextSizeByCategory(context, 16, 'button'),
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              icon,
              size: getResponsiveTextSizeByCategory(context, 20, 'body'),
              color: Colors.blueAccent
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: getResponsiveTextSizeByCategory(context, 16, 'body'),
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
}

// Create Event Page
class CreateEventPage extends StatefulWidget {
  final String schoolName;
  final String selectedClass;

  const CreateEventPage({
    Key? key,
    required this.schoolName,
    required this.selectedClass,
  }) : super(key: key);

  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedEventType = 'Academic';
  bool _isLoading = false;
  String? _teacherSchool;

  final List<String> _eventTypes = [
    'Academic',
    'Sports',
    'Cultural',
    'Meeting',
    'Examination',
    'Holiday',
    'Other'
  ];

  // Add responsive text size functions here too
  double getResponsiveTextSizeByCategory(BuildContext context, double baseSize, String category) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double diagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);

    bool isTablet = diagonal > 1100;
    bool isLargePhone = screenWidth > 400 && screenWidth < 600;

    double scaleFactor;

    // Category-specific scaling adjustments
    double categoryMultiplier = 1.0;
    switch (category.toLowerCase()) {
      case 'title':
      case 'heading':
        categoryMultiplier = isTablet ? 0.9 : 1.0;
        break;
      case 'body':
      case 'content':
        categoryMultiplier = isTablet ? 0.95 : 1.0;
        break;
      case 'caption':
      case 'small':
        categoryMultiplier = isTablet ? 1.0 : 1.0;
        break;
      case 'button':
        categoryMultiplier = isTablet ? 0.9 : 1.0;
        break;
      default:
        categoryMultiplier = 1.0;
    }

    if (isTablet) {
      scaleFactor = (screenWidth / 768.0) * 0.85 * categoryMultiplier;
      scaleFactor = scaleFactor.clamp(0.9, 1.4);
    } else if (isLargePhone) {
      scaleFactor = (screenWidth / 414.0) * categoryMultiplier;
      scaleFactor = scaleFactor.clamp(0.8, 1.2);
    } else {
      scaleFactor = (screenWidth / 375.0) * categoryMultiplier;
      scaleFactor = scaleFactor.clamp(0.7, 1.3);
    }

    return baseSize * scaleFactor;
  }

  @override
  void initState() {
    super.initState();
    _getTeacherSchool();
  }

  Future<void> _getTeacherSchool() async {
    try {
      String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      if (currentUserEmail != null) {
        DocumentSnapshot teacherDoc = await _firestore
            .collection('Teachers_Details')
            .doc(currentUserEmail)
            .get();

        if (teacherDoc.exists) {
          Map<String, dynamic> teacherData = teacherDoc.data() as Map<String, dynamic>;
          setState(() {
            _teacherSchool = teacherData['school'];
          });
        }
      }
    } catch (e) {
      print('Error fetching teacher school: $e');
    }
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String actualSchool = _teacherSchool ?? widget.schoolName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Event ,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: getResponsiveTextSizeByCategory(context, 18, 'title'),
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.blueAccent.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.event,
                      size: getResponsiveTextSizeByCategory(context, 60, 'title'),
                      color: Colors.blueAccent,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Create Event for $actualSchool',
                      style: TextStyle(
                        fontSize: getResponsiveTextSizeByCategory(context, 20, 'title'),
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    _buildEventTitleField(),
                    SizedBox(height: 16),
                    _buildEventDescriptionField(),
                    SizedBox(height: 16),
                    _buildEventTypeDropdown(),
                    SizedBox(height: 16),
                    _buildEventLocationField(),
                    SizedBox(height: 16),
                    _buildDateTimePickers(),
                    SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTitleField() {
    return TextFormField(
      controller: _eventTitleController,
      decoration: InputDecoration(
        labelText: 'Event Title',
        labelStyle: TextStyle(fontSize: getResponsiveTextSizeByCategory(context, 16, 'body')),
        hintText: 'Enter event title',
        hintStyle: TextStyle(fontSize: getResponsiveTextSizeByCategory(context, 14, 'body')),
        prefixIcon: Icon(Icons.title, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      style: TextStyle(fontSize: getResponsiveTextSizeByCategory(context, 16, 'body')),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event title';
        }
        return null;
      },
    );
  }



  Widget _buildEventDescriptionField() {
    return TextFormField(
      controller: _eventDescriptionController,
      maxLines: 3,
      style: TextStyle(
        fontSize: getResponsiveTextSizeByCategory(context, 16, 'title'),
      ),
      decoration: InputDecoration(
        labelText: 'Event Description',
        labelStyle: TextStyle(
          fontSize: getResponsiveTextSizeByCategory(context, 16, 'label'),
        ),
        hintText: 'Enter event description',
        hintStyle: TextStyle(
          fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
        ),
        prefixIcon: Icon(Icons.description, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event description';
        }
        return null;
      },
    );
  }

  Widget _buildEventTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEventType,
      style: TextStyle(
        fontSize: getResponsiveTextSizeByCategory(context, 16, 'title'),
        color: Colors.black,
      ),
      decoration: InputDecoration(
        labelText: 'Event Type',
        labelStyle: TextStyle(
          fontSize: getResponsiveTextSizeByCategory(context, 16, 'label'),
        ),
        prefixIcon: Icon(Icons.category, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      items: _eventTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: TextStyle(
              fontSize: getResponsiveTextSizeByCategory(context, 16, 'title'),
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedEventType = newValue!;
        });
      },
    );
  }

  Widget _buildEventLocationField() {
    return TextFormField(
      controller: _eventLocationController,
      style: TextStyle(
        fontSize: getResponsiveTextSizeByCategory(context, 16, 'title'),
      ),
      decoration: InputDecoration(
        labelText: 'Event Location',
        labelStyle: TextStyle(
          fontSize: getResponsiveTextSizeByCategory(context, 16, 'label'),
        ),
        hintText: 'Enter event location',
        hintStyle: TextStyle(
          fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
        ),
        prefixIcon: Icon(Icons.location_on, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event location';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimePickers() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          fontSize: getResponsiveTextSizeByCategory(context, 16, 'title'),
                          color: _selectedDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blueAccent),
                      SizedBox(width: 10),
                      Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          fontSize: getResponsiveTextSizeByCategory(context, 16, 'title'),
                          color: _selectedTime == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDate == null || _selectedTime == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please select both date and time',
              style: TextStyle(
                color: Colors.red,
                fontSize: getResponsiveTextSizeByCategory(context, 12, 'body'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      icon: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Icon(Icons.save),
      label: Text(
        _isLoading ? 'Saving...' : 'Save Event',
        style: TextStyle(
          fontSize: getResponsiveTextSizeByCategory(context, 18, 'button'),
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      onPressed: _isLoading ? null : _saveEvent,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Changed: Cannot select past dates
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select both date and time',
            style: TextStyle(
              fontSize: getResponsiveTextSizeByCategory(context, 14, 'title'),
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use teacher's actual school instead of widget.schoolName
      String actualSchool = _teacherSchool ?? widget.schoolName;

      // Combine date and time
      final DateTime eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Check if the event date/time is in the past
      if (eventDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot create event for past date/time',
              style: TextStyle(
                fontSize: getResponsiveTextSizeByCategory(context, 14,'title'),
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current user info
      String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

      // Create event data
      final Map<String, dynamic> eventData = {
        'title': _eventTitleController.text.trim(),
        'description': _eventDescriptionController.text.trim(),
        'type': _selectedEventType,
        'location': _eventLocationController.text.trim(),
        'dateTime': Timestamp.fromDate(eventDateTime),
        'createdAt': Timestamp.now(),
        'createdBy': currentUserEmail ?? 'Unknown',
        'schoolName': actualSchool, // Use teacher's actual school
        'className': widget.selectedClass,
        'isActive': true,
      };

      // Generate a unique document ID to avoid conflicts
      String docId = '${_eventTitleController.text.trim()}_${DateTime.now().millisecondsSinceEpoch}';

      // Save to Firestore - Using teacher's actual school
      await _firestore
          .collection('Schools')
          .doc(actualSchool) // Use teacher's actual school
          .collection('Upcoming_School_Events')
          .doc(docId)
          .set(eventData);

      // Clear form
      _clearForm();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event saved successfully for $actualSchool!',
            style: TextStyle(
              fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
            ),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving event: $e',
            style: TextStyle(
              fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      // Check if selected date is today and time is in the past
      if (_selectedDate != null) {
        final now = DateTime.now();
        final selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );

        if (selectedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cannot select past time for today',
                style: TextStyle(
                  fontSize: getResponsiveTextSizeByCategory(context, 14, 'body'),
                ),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      setState(() {
        _selectedTime = picked;
      });
    }
  }


  void _clearForm() {
    _eventTitleController.clear();
    _eventDescriptionController.clear();
    _eventLocationController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedEventType = 'Academic';
    });
  }

}