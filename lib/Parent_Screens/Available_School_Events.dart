import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Log_In_And_Register_Screens/Login_Page.dart';

class Available_School_Events extends StatefulWidget {
  static const String id = 'upcoming_school_events';

  const Available_School_Events({
    Key? key,
    required String schoolName,
    required String className,
    required String studentClass,
    required String studentName
  }) : super(key: key);

  @override
  _Available_School_EventsState createState() => _Available_School_EventsState();
}

class _Available_School_EventsState extends State<Available_School_Events> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _schoolName;
  String? _studentName;
  String? _studentClass;
  bool _isLoading = true;

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
        _isLoading = false;
      });

      print('🎓 Parent Data Loaded:');
      print('School: $_schoolName');
      print('Student: $_studentName');
      print('Class: $_studentClass');
    } catch (e) {
      print('❌ Error loading parent data: $e');
      setState(() {
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

  // Helper method to check if screen is tablet
  bool _isTabletScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600 && screenWidth < 1200;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = _isSmallScreen(context);
    final isTablet = _isTabletScreen(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('School Events'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
      );
    }

    if (_schoolName == null || _schoolName!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('School Events'),
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
                    color: Colors.red
                ),
                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                Text(
                  'No School Data Found',
                  style: TextStyle(
                      fontSize: _getResponsiveValue(context, 18, 22, 26),
                      fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: _getResponsiveValue(context, 8, 12, 16)),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveValue(context, 16, 32, 48)
                  ),
                  child: Text(
                    'Please login again to access school events',
                    style: TextStyle(
                        fontSize: _getResponsiveValue(context, 14, 16, 18),
                        color: Colors.grey
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: _getResponsiveValue(context, 16, 20, 24),
                        vertical: _getResponsiveValue(context, 8, 10, 12)
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                          fontSize: _getResponsiveValue(context, 14, 16, 18)
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Events',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _getResponsiveValue(context, 18, 20, 22)
              ),
            ),
            if (!isSmall) // Hide subtitle on very small screens
              Text(
                _schoolName!,
                style: TextStyle(
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
                    fontWeight: FontWeight.normal
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
                _loadParentData();
              });
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Schools')
              .doc(_schoolName!)
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
                child: Padding(
                  padding: EdgeInsets.all(_getResponsiveValue(context, 16, 24, 32)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          Icons.error_outline,
                          size: _getResponsiveValue(context, 60, 80, 100),
                          color: Colors.red
                      ),
                      SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                      Text(
                        'Error loading events',
                        style: TextStyle(
                            fontSize: _getResponsiveValue(context, 18, 22, 26),
                            color: Colors.red
                        ),
                      ),
                      SizedBox(height: _getResponsiveValue(context, 8, 12, 16)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveValue(context, 16, 32, 48)
                        ),
                        child: Text(
                          '${snapshot.error}',
                          style: TextStyle(
                              fontSize: _getResponsiveValue(context, 12, 14, 16),
                              color: Colors.grey
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: _getResponsiveValue(context, 16, 20, 24),
                              vertical: _getResponsiveValue(context, 8, 10, 12)
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                                fontSize: _getResponsiveValue(context, 14, 16, 18)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(_getResponsiveValue(context, 16, 24, 32)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: _getResponsiveValue(context, 80, 100, 120),
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: _getResponsiveValue(context, 16, 20, 24)),
                      Text(
                        'No Upcoming Events',
                        style: TextStyle(
                          fontSize: _getResponsiveValue(context, 24, 28, 32),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: _getResponsiveValue(context, 8, 12, 16)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveValue(context, 16, 32, 48)
                        ),
                        child: Text(
                          'There are no events scheduled for $_schoolName',
                          style: TextStyle(
                            fontSize: _getResponsiveValue(context, 16, 18, 20),
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate responsive grid properties
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1200) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 800) {
                    crossAxisCount = 2;
                  }

                  double padding = _getResponsiveValue(context, 12, 16, 20);
                  double cardSpacing = _getResponsiveValue(context, 12, 16, 20);

                  if (crossAxisCount == 1) {
                    // Single column layout for mobile
                    return ListView.builder(
                      padding: EdgeInsets.all(padding),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildEventCard(context, data, padding, cardSpacing);
                      },
                    );
                  } else {
                    // Grid layout for tablet and desktop
                    return GridView.builder(
                      padding: EdgeInsets.all(padding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: cardSpacing,
                        mainAxisSpacing: cardSpacing,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildEventCard(context, data, padding, cardSpacing);
                      },
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> data, double padding, double spacing) {
    final eventDateTime = (data['dateTime'] as Timestamp).toDate();
    final now = DateTime.now();
    final isUpcoming = eventDateTime.isAfter(now);
    final relativeDate = _getRelativeDate(eventDateTime);
    final shouldShow = eventDateTime.isAfter(DateTime.now().subtract(Duration(days: 7)));
    final isSmall = _isSmallScreen(context);

    if (!shouldShow) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      child: Card(
        elevation: _getResponsiveValue(context, 4, 6, 8),
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
            gradient: LinearGradient(
              colors: isUpcoming
                  ? [Colors.white, Colors.blue.shade50]
                  : [Colors.grey.shade100, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(_getResponsiveValue(context, 12, 16, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_getResponsiveValue(context, 6, 8, 10)),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.blueAccent : Colors.grey,
                        borderRadius: BorderRadius.circular(_getResponsiveValue(context, 6, 8, 10)),
                      ),
                      child: Icon(
                        _getEventIcon(data['type']),
                        color: Colors.white,
                        size: _getResponsiveValue(context, 18, 20, 24),
                      ),
                    ),
                    SizedBox(width: _getResponsiveValue(context, 8, 12, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: _getResponsiveValue(context, 16, 18, 20),
                              fontWeight: FontWeight.bold,
                              color: isUpcoming ? Colors.black87 : Colors.grey.shade600,
                            ),
                            maxLines: isSmall ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: _getResponsiveValue(context, 4, 6, 8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: _getResponsiveValue(context, 6, 8, 10),
                                vertical: _getResponsiveValue(context, 3, 4, 5)
                            ),
                            decoration: BoxDecoration(
                              color: isUpcoming
                                  ? Colors.blueAccent.shade100
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                            ),
                            child: Text(
                              data['type'] ?? 'Event',
                              style: TextStyle(
                                fontSize: _getResponsiveValue(context, 10, 12, 14),
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
                        padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveValue(context, 6, 8, 10),
                            vertical: _getResponsiveValue(context, 3, 4, 5)
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(_getResponsiveValue(context, 8, 10, 12)),
                        ),
                        child: Text(
                          'Past',
                          style: TextStyle(
                            fontSize: _getResponsiveValue(context, 9, 10, 12),
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: _getResponsiveValue(context, 8, 12, 16)),

                // Description
                Text(
                  data['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 12, 14, 16),
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: isSmall ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _getResponsiveValue(context, 8, 12, 16)),

                // Date and Time Container
                Container(
                  padding: EdgeInsets.all(_getResponsiveValue(context, 8, 12, 16)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(_getResponsiveValue(context, 6, 8, 10)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                              Icons.calendar_today,
                              size: _getResponsiveValue(context, 14, 16, 18),
                              color: Colors.blueAccent
                          ),
                          SizedBox(width: _getResponsiveValue(context, 6, 8, 10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}',
                                  style: TextStyle(
                                    fontSize: _getResponsiveValue(context, 12, 14, 16),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (relativeDate.isNotEmpty)
                                  Text(
                                    relativeDate,
                                    style: TextStyle(
                                      fontSize: _getResponsiveValue(context, 10, 12, 14),
                                      fontWeight: FontWeight.bold,
                                      color: isUpcoming ? Colors.green.shade600 : Colors.orange.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isSmall) ...[
                        SizedBox(height: _getResponsiveValue(context, 4, 6, 8)),
                        Row(
                          children: [
                            Icon(
                                Icons.access_time,
                                size: _getResponsiveValue(context, 14, 16, 18),
                                color: Colors.blueAccent
                            ),
                            SizedBox(width: _getResponsiveValue(context, 6, 8, 10)),
                            Text(
                              TimeOfDay.fromDateTime(eventDateTime).format(context),
                              style: TextStyle(
                                fontSize: _getResponsiveValue(context, 12, 14, 16),
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: _getResponsiveValue(context, 6, 8, 10)),

                // Location and Details Row
                Row(
                  children: [
                    Icon(
                        Icons.location_on,
                        size: _getResponsiveValue(context, 14, 16, 18),
                        color: Colors.grey.shade600
                    ),
                    SizedBox(width: _getResponsiveValue(context, 6, 8, 10)),
                    Expanded(
                      child: Text(
                        data['location'] ?? 'No location',
                        style: TextStyle(
                          fontSize: _getResponsiveValue(context, 12, 14, 16),
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showEventDetails(context, data),
                      child: Text(
                        isSmall ? 'Details' : 'View Details',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: _getResponsiveValue(context, 12, 14, 16),
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
      return ''; // For events older than 7 days (won't be shown)
    }
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> data) {
    final eventDateTime = (data['dateTime'] as Timestamp).toDate();
    final isSmall = _isSmallScreen(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getResponsiveValue(context, 12, 16, 20)),
          ),
          title: Row(
            children: [
              Icon(
                _getEventIcon(data['type']),
                color: Colors.blueAccent,
                size: _getResponsiveValue(context, 20, 24, 28),
              ),
              SizedBox(width: _getResponsiveValue(context, 6, 8, 10)),
              Expanded(
                child: Text(
                  data['title'] ?? 'Event Details',
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 18, 20, 24),
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
                _buildDetailRow('School', data['schoolName'] ?? _schoolName ?? 'N/A', Icons.school),
                if (data['createdBy'] != null)
                  _buildDetailRow('Created By', data['createdBy'], Icons.person),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveValue(context, 8, 12, 16),
                    vertical: _getResponsiveValue(context, 4, 6, 8)
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
                  ),
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
      padding: EdgeInsets.symmetric(vertical: _getResponsiveValue(context, 6, 8, 10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              icon,
              size: _getResponsiveValue(context, 18, 20, 24),
              color: Colors.blueAccent
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
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: _getResponsiveValue(context, 2, 4, 6)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _getResponsiveValue(context, 14, 16, 18),
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