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

  // Helper method to get responsive font size based on screen width
  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate scale factor based on screen dimensions
    // Using a combination of width and height for better responsiveness
    double scaleFactor = (screenWidth / 375) * 0.7 + (screenHeight / 667) * 0.3;

    // Clamp the scale factor to prevent too small or too large text
    scaleFactor = scaleFactor.clamp(0.8, 2.0);

    return baseSize * scaleFactor;
  }

  // Helper method to get responsive padding/margin
  double _getResponsivePadding(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 375;
    scaleFactor = scaleFactor.clamp(0.8, 2.0);
    return baseSize * scaleFactor;
  }

  // Helper method to get responsive icon size
  double _getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / 375;
    scaleFactor = scaleFactor.clamp(0.8, 2.2);
    return baseSize * scaleFactor;
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
            padding: EdgeInsets.all(_getResponsivePadding(context, 16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    Icons.error_outline,
                    size: _getResponsiveIconSize(context, 60),
                    color: Colors.red
                ),
                SizedBox(height: _getResponsivePadding(context, 16)),
                Text(
                  'No School Data Found',
                  style: TextStyle(
                      fontSize: _getResponsiveFontSize(context, 18),
                      fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: _getResponsivePadding(context, 8)),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: _getResponsivePadding(context, 16)
                  ),
                  child: Text(
                    'Please login again to access school events',
                    style: TextStyle(
                        fontSize: _getResponsiveFontSize(context, 14),
                        color: Colors.grey
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: _getResponsivePadding(context, 16)),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: _getResponsivePadding(context, 16),
                        vertical: _getResponsivePadding(context, 8)
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 14)
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
                  fontSize: _getResponsiveFontSize(context, 18)
              ),
            ),
            if (!isSmall) // Hide subtitle on very small screens
              Text(
                _schoolName!,
                style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 14),
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
            iconSize: _getResponsiveIconSize(context, 24),
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
                  padding: EdgeInsets.all(_getResponsivePadding(context, 16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          Icons.error_outline,
                          size: _getResponsiveIconSize(context, 60),
                          color: Colors.red
                      ),
                      SizedBox(height: _getResponsivePadding(context, 16)),
                      Text(
                        'Error loading events',
                        style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 18),
                            color: Colors.red
                        ),
                      ),
                      SizedBox(height: _getResponsivePadding(context, 8)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: _getResponsivePadding(context, 16)
                        ),
                        child: Text(
                          '${snapshot.error}',
                          style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 12),
                              color: Colors.grey
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: _getResponsivePadding(context, 16)),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: _getResponsivePadding(context, 16),
                              vertical: _getResponsivePadding(context, 8)
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 14)
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
                  padding: EdgeInsets.all(_getResponsivePadding(context, 16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: _getResponsiveIconSize(context, 80),
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: _getResponsivePadding(context, 16)),
                      Text(
                        'No Upcoming Events',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: _getResponsivePadding(context, 8)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: _getResponsivePadding(context, 16)
                        ),
                        child: Text(
                          'There are no events scheduled for $_schoolName',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 16),
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

                  double padding = _getResponsivePadding(context, 12);
                  double cardSpacing = _getResponsivePadding(context, 12);

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
        elevation: _getResponsivePadding(context, 4),
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_getResponsivePadding(context, 12)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_getResponsivePadding(context, 12)),
            gradient: LinearGradient(
              colors: isUpcoming
                  ? [Colors.white, Colors.blue.shade50]
                  : [Colors.grey.shade100, Colors.grey.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(_getResponsivePadding(context, 12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(_getResponsivePadding(context, 6)),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.blueAccent : Colors.grey,
                        borderRadius: BorderRadius.circular(_getResponsivePadding(context, 6)),
                      ),
                      child: Icon(
                        _getEventIcon(data['type']),
                        color: Colors.white,
                        size: _getResponsiveIconSize(context, 18),
                      ),
                    ),
                    SizedBox(width: _getResponsivePadding(context, 8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'No Title',
                            style: TextStyle(
                              fontSize: _getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: isUpcoming ? Colors.black87 : Colors.grey.shade600,
                            ),
                            maxLines: isSmall ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: _getResponsivePadding(context, 4)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: _getResponsivePadding(context, 6),
                                vertical: _getResponsivePadding(context, 3)
                            ),
                            decoration: BoxDecoration(
                              color: isUpcoming
                                  ? Colors.blueAccent.shade100
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(_getResponsivePadding(context, 8)),
                            ),
                            child: Text(
                              data['type'] ?? 'Event',
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 10),
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
                            horizontal: _getResponsivePadding(context, 6),
                            vertical: _getResponsivePadding(context, 3)
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(_getResponsivePadding(context, 8)),
                        ),
                        child: Text(
                          'Past',
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(context, 9),
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: _getResponsivePadding(context, 8)),

                // Description
                Text(
                  data['description'] ?? 'No description',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 12),
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: isSmall ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _getResponsivePadding(context, 8)),

                // Date and Time Container
                Container(
                  padding: EdgeInsets.all(_getResponsivePadding(context, 8)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(_getResponsivePadding(context, 6)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                              Icons.calendar_today,
                              size: _getResponsiveIconSize(context, 14),
                              color: Colors.blueAccent
                          ),
                          SizedBox(width: _getResponsivePadding(context, 6)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}',
                                  style: TextStyle(
                                    fontSize: _getResponsiveFontSize(context, 12),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (relativeDate.isNotEmpty)
                                  Text(
                                    relativeDate,
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(context, 10),
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
                        SizedBox(height: _getResponsivePadding(context, 4)),
                        Row(
                          children: [
                            Icon(
                                Icons.access_time,
                                size: _getResponsiveIconSize(context, 14),
                                color: Colors.blueAccent
                            ),
                            SizedBox(width: _getResponsivePadding(context, 6)),
                            Text(
                              TimeOfDay.fromDateTime(eventDateTime).format(context),
                              style: TextStyle(
                                fontSize: _getResponsiveFontSize(context, 12),
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
                SizedBox(height: _getResponsivePadding(context, 6)),

                // Location and Details Row
                Row(
                  children: [
                    Icon(
                        Icons.location_on,
                        size: _getResponsiveIconSize(context, 14),
                        color: Colors.grey.shade600
                    ),
                    SizedBox(width: _getResponsivePadding(context, 6)),
                    Expanded(
                      child: Text(
                        data['location'] ?? 'No location',
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context, 12),
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
                          fontSize: _getResponsiveFontSize(context, 12),
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
            borderRadius: BorderRadius.circular(_getResponsivePadding(context, 12)),
          ),
          title: Row(
            children: [
              Icon(
                _getEventIcon(data['type']),
                color: Colors.blueAccent,
                size: _getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: _getResponsivePadding(context, 6)),
              Expanded(
                child: Text(
                  data['title'] ?? 'Event Details',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 18),
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
                    horizontal: _getResponsivePadding(context, 8),
                    vertical: _getResponsivePadding(context, 4)
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: _getResponsiveFontSize(context, 14),
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
      padding: EdgeInsets.symmetric(vertical: _getResponsivePadding(context, 6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              icon,
              size: _getResponsiveIconSize(context, 18),
              color: Colors.blueAccent
          ),
          SizedBox(width: _getResponsivePadding(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 12),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: _getResponsivePadding(context, 2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 14),
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