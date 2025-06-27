import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedEventType = 'Academic';
  bool _isLoading = false;

  final List<String> _eventTypes = [
    'Academic',
    'Sports',
    'Cultural',
    'Meeting',
    'Examination',
    'Holiday',
    'Other'
  ];

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'School Events Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: _viewAllEvents,
            tooltip: 'View All Events',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shadowColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
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
                      size: 80,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Create New Event',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
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
        hintText: 'Enter event title',
        prefixIcon: Icon(Icons.title, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
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
      decoration: InputDecoration(
        labelText: 'Event Description',
        hintText: 'Enter event description',
        prefixIcon: Icon(Icons.description, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
      decoration: InputDecoration(
        labelText: 'Event Type',
        prefixIcon: Icon(Icons.category, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      items: _eventTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
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
      decoration: InputDecoration(
        labelText: 'Event Location',
        hintText: 'Enter event location',
        prefixIcon: Icon(Icons.location_on, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
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
                          fontSize: 16,
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
                    borderRadius: BorderRadius.circular(10),
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
                          fontSize: 16,
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
              style: TextStyle(color: Colors.red, fontSize: 12),
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
      label: Text(_isLoading ? 'Saving...' : 'Save Event'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _isLoading ? null : _saveEvent,
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
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
          content: Text('Please select both date and time'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final DateTime eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create event data
      final Map<String, dynamic> eventData = {
        'title': _eventTitleController.text.trim(),
        'description': _eventDescriptionController.text.trim(),
        'type': _selectedEventType,
        'location': _eventLocationController.text.trim(),
        'dateTime': Timestamp.fromDate(eventDateTime),
        'createdAt': Timestamp.now(),
        'createdBy': 'Teacher', // You can replace this with actual teacher data
        'schoolName': widget.schoolName,
        'className': widget.selectedClass,
        'isActive': true,
      };

      // Get reference to the document
      final DocumentReference eventRef = _firestore
          .collection('Schools')
          .doc(widget.schoolName)
          .collection('Classes')
          .doc(widget.selectedClass)
          .collection('Upcoming_School_Events')
          .doc(); // Auto-generate document ID

      // Save to Firestore
      await eventRef.set(eventData);

      // Clear form
      _clearForm();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving event: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
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

  void _viewAllEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventsListPage(
          schoolName: widget.schoolName,
          selectedClass: widget.selectedClass,
        ),
      ),
    );
  }
}

// Events List Page to view all events
class EventsListPage extends StatelessWidget {
  final String schoolName;
  final String selectedClass;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EventsListPage({
    Key? key,
    required this.schoolName,
    required this.selectedClass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Events'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('Schools')
            .doc(schoolName)
            .collection('Classes')
            .doc(selectedClass)
            .collection('Upcoming_School_Events')
            .orderBy('dateTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
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
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No events found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final eventDateTime = (data['dateTime'] as Timestamp).toDate();

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(
                      Icons.event,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'No Title',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'] ?? ''),
                      SizedBox(height: 4),
                      Text(
                        '${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year} at ${TimeOfDay.fromDateTime(eventDateTime).format(context)}',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Location: ${data['location'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      data['type'] ?? 'Event',
                      style: TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.blueAccent.shade100,
                  ),
                  onTap: () {
                    _showEventDetails(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> data) {
    final eventDateTime = (data['dateTime'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['title'] ?? 'Event Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${data['description'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Type: ${data['type'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Location: ${data['location'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Date: ${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}'),
              SizedBox(height: 8),
              Text('Time: ${TimeOfDay.fromDateTime(eventDateTime).format(context)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}