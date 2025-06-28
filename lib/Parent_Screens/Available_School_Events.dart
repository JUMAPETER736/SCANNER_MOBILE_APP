import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Main Upcoming School Events Page
class Upcoming_School_Event extends StatefulWidget {
  final String schoolName;
  final String selectedClass;

  const Upcoming_School_Event({
    Key? key,
    required this.schoolName,
    required this.selectedClass,
  }) : super(key: key);

  @override
  _Upcoming_School_EventState createState() => _Upcoming_School_EventState();
}

class _Upcoming_School_EventState extends State<Upcoming_School_Event> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _teacherSchool;

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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Available_School_Events(
                    schoolName: actualSchool,
                    selectedClass: widget.selectedClass,
                  ),
                ),
              );
            },
            tooltip: 'View All Events',
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
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading events',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Events Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first event for $actualSchool',
                      style: TextStyle(
                        fontSize: 16,
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
                                      size: 20,
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
                                            fontSize: 18,
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
                                              fontSize: 12,
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
                                          fontSize: 10,
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
                                  fontSize: 14,
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
                                    Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (relativeDate.isNotEmpty)
                                          Text(
                                            relativeDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isUpcoming ? Colors.green.shade600 : Colors.orange.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(width: 16),
                                    Icon(Icons.access_time, size: 16, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      TimeOfDay.fromDateTime(eventDateTime).format(context),
                                      style: TextStyle(
                                        fontSize: 14,
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
                                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data['location'] ?? 'No location',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showEventDetails(context, data),
                                    child: Text(
                                      'View Details',
                                      style: TextStyle(
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
      case 'workshop':
        return Icons.engineering;
      case 'conference':
        return Icons.mic;
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
              Icon(_getEventIcon(data['type']), color: Colors.blueAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['title'] ?? 'Event Details',
                  style: TextStyle(
                    fontSize: 20,
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
                style: TextStyle(color: Colors.blueAccent),
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
          Icon(icon, size: 20, color: Colors.blueAccent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
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

// Available School Events Page (View All Events)
class Available_School_Events extends StatefulWidget {
  final String schoolName;
  final String selectedClass;

  const Available_School_Events({
    Key? key,
    required this.schoolName,
    required this.selectedClass,
  }) : super(key: key);

  @override
  _Available_School_EventsState createState() => _Available_School_EventsState();
}

class _Available_School_EventsState extends State<Available_School_Events> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _teacherSchool;
  bool _isLoading = true;

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
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching teacher school: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String actualSchool = _teacherSchool ?? widget.schoolName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available Events - $actualSchool',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _getTeacherSchool();
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
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading events...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
            : StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Schools')
              .doc(actualSchool)
              .collection('Upcoming_School_Events')
              .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime.now().subtract(Duration(hours: 1))))
              .orderBy('dateTime', descending: false)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorWidget(snapshot.error.toString());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyWidget(actualSchool);
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildEventCard(data);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Unable to Load Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _getTeacherSchool();
              },
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String schoolName) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 20),
            Text(
              'No Events Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'There are currently no upcoming events for $schoolName.\nCheck back later for new events!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data) {
    final eventDateTime = (data['dateTime'] as Timestamp).toDate();
    final now = DateTime.now();
    final isUpcoming = eventDateTime.isAfter(now);
    final relativeDate = _getRelativeDate(eventDateTime);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 6,
        shadowColor: Colors.blueAccent.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isUpcoming
                  ? [Colors.white, Colors.blue.shade50]
                  : [Colors.grey.shade50, Colors.grey.shade100],
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
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUpcoming ? Colors.blueAccent : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getEventIcon(data['type']),
                        color: Colors.white,
                        size: 22,
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isUpcoming
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isUpcoming
                                      ? Colors.blueAccent.shade100
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data['type'] ?? 'Event',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isUpcoming
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              if (relativeDate.isNotEmpty) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isUpcoming
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    relativeDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isUpcoming
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isUpcoming)
                      Container(
                        padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Past',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  data['description'] ?? 'No description available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 16, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        TimeOfDay.fromDateTime(eventDateTime).format(context),
                        style: TextStyle(
                          fontSize: 14,
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
                    Icon(Icons.location_on,
                        size: 16, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['location'] ?? 'No location specified',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showEventDetails(context, data),
                      child: Text(
                        'View Details',
                        style: TextStyle(
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
      case 'workshop':
        return Icons.engineering;
      case 'conference':
        return Icons.mic;
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
              Icon(_getEventIcon(data['type']), color: Colors.blueAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['title'] ?? 'Event Details',
                  style: TextStyle(
                    fontSize: 20,
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
                style: TextStyle(color: Colors.blueAccent),
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
          Icon(icon, size: 20, color: Colors.blueAccent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _selectedType = 'Academic';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  final List<String> _eventTypes = [
    'Academic',
    'Sports',
    'Cultural',
    'Meeting',
    'Examination',
    'Holiday',
    'Workshop',
    'Conference',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Upcoming_School_Events')
          .add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'type': _selectedType,
        'dateTime': Timestamp.fromDate(eventDateTime),
        'createdAt': Timestamp.now(),
        'schoolName': widget.schoolName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create New Event',
          style: TextStyle(fontWeight: FontWeight.bold),
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
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an event title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _eventTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an event type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a date';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        readOnly: true,
                        onTap: () => _selectTime(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a time';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Text(
                      'Create Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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