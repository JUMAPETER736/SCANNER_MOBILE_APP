import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Class_Selection extends StatefulWidget {
  @override
  _Class_SelectionState createState() => _Class_SelectionState();
}

class _Class_SelectionState extends State<Class_Selection> {
  List<String> selectedClasses = [];
  Map<String, List<String>> selectedSubjectsByClass = {};
  String? selectedSchool;
  bool isSaved = false;
  bool isLoading = false;

  // Track unavailable subjects by school and class
  Map<String, Map<String, List<String>>> unavailableSubjectsBySchoolAndClass = {
  };
  String? currentUserEmail;

  final List<String> schools = [
    'Balaka Secondary School',
    'Bandawe Boys Secondary School',
    'Blantyre Secondary School',
    'Bwaila Secondary School',
    'Chaminade Boys Secondary School',
    'Chayamba Secondary School',
    'Chikwawa Catholic Secondary School',
    'Chikwawa Secondary School',
    'Chilumba Boys Secondary School',
    'Chipasula Secondary School',
    'Chipoka Secondary School',
    'Chiradzulu Secondary School',
    'Chitipa Secondary School',
    'Dedza Boys Secondary School',
    'Dowa Secondary School',
    'Dzenza Secondary School',
    'Ekwendeni Girls Secondary School',
    'Euthini Secondary School',
    'Kasungu Secondary School',
    'Katoto Secondary School',
    'Lilongwe Girls Secondary School',
    'Likoma Secondary School',
    'Likuni Boys Secondary School',
    'Likuni Girls Secondary School',
    'Livingstonia Secondary School',
    'Luchenza Secondary School',
    'Ludzi Girls Secondary School',
    'Madisi Secondary School',
    'Magawa Secondary School',
    'Machinga Secondary School',
    'Mchinji Secondary School',
    'Mayani Secondary School',
    'Mbomba Secondary School',
    'Mitundu Secondary School',
    'Mikoke Secondary School',
    'Mzimba Secondary School',
    'Mzuzu Government Secondary School',
    'Mwanza Catholic Secondary School',
    'Mwanza Secondary School',
    'Namitete Secondary School',
    'Nankhunda Secondary School',
    'Neno Secondary School',
    'Ngabu Secondary School',
    'Nkhamenya Girls Secondary School',
    'Nkhatabay Secondary School',
    'Nkhotakota Secondary School',
    'Ntcheu Secondary School',
    'Ntchisi Boys Secondary School',
    'Our Lady of Wisdom Secondary School',
    'Phalombe Secondary School',
    'Providence Secondary School',
    'Robert Blake Boys Secondary School',
    'Robert Laws Secondary School',
    'Rumphi Boys Secondary School',
    'Salima Secondary School',
    'St. Charles Lwanga Secondary School',
    'St. John Bosco Boys Secondary School',
    'St. Johns Boys Secondary School',
    'St. Kizito Secondary School',
    'St. Mary\'s Secondary School',
    'St. Michael\'s Girls Secondary School',
    'St. Patrick\'s Secondary School',
    'St. Pius XII Seminary',
    'St. Stella Maris Secondary School',
    'Thyolo Secondary School',
    'Umbwi Boys Secondary School',
    'William Murray Boys Secondary School',
    'Zomba Catholic Secondary School',
    'Zomba Urban Secondary School',
  ];

  final List<String> classes = ['FORM 1', 'FORM 2', 'FORM 3', 'FORM 4'];

  final Map<String, List<String>> classSubjects = {
    'FORM 1': [
      'AGRICULTURE',
      'BIOLOGY',
      'BIBLE KNOWLEDGE',
      'COMPUTER SCIENCE',
      'CHEMISTRY',
      'CHICHEWA',
      'ENGLISH',
      'LIFE SKILLS',
      'MATHEMATICS',
      'PHYSICS',
      'SOCIAL STUDIES'
    ],
    'FORM 2': [
      'AGRICULTURE',
      'BIOLOGY',
      'BIBLE KNOWLEDGE',
      'COMPUTER SCIENCE',
      'CHEMISTRY',
      'CHICHEWA',
      'ENGLISH',
      'LIFE SKILLS',
      'MATHEMATICS',
      'PHYSICS',
      'SOCIAL STUDIES'
    ],
    'FORM 3': [
      'AGRICULTURE',
      'BIOLOGY',
      'BIBLE KNOWLEDGE',
      'COMPUTER SCIENCE',
      'CHEMISTRY',
      'CHICHEWA',
      'ENGLISH',
      'LIFE SKILLS',
      'MATHEMATICS',
      'PHYSICS',
      'SOCIAL STUDIES'
    ],
    'FORM 4': [
      'AGRICULTURE',
      'BIOLOGY',
      'BIBLE KNOWLEDGE',
      'COMPUTER SCIENCE',
      'CHEMISTRY',
      'CHICHEWA',
      'ENGLISH',
      'LIFE SKILLS',
      'MATHEMATICS',
      'PHYSICS',
      'SOCIAL STUDIES'
    ]
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      await _getCurrentUserEmail();
      await _fetchUnavailableSubjects();
      await _checkSavedSelections();
    } catch (e) {
      _showToast('Error initializing data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Get the current user's email
  Future<void> _getCurrentUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email;
    } else {
      throw Exception('No authenticated user found');
    }
  }

  // Fetch all subjects that are already taken by other teachers
  Future<void> _fetchUnavailableSubjects() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .get();

      unavailableSubjectsBySchoolAndClass.clear();

      for (var doc in querySnapshot.docs) {
        if (doc.data() != null) {
          var data = doc.data() as Map<String, dynamic>;
          String docId = doc.id;

          // Skip the current user's document
          if (docId == currentUserEmail) continue;

          // Check if required fields exist
          if (data.containsKey('school') &&
              data.containsKey('classes') &&
              data.containsKey('subjects')) {
            String school = data['school'] as String;
            List<String> classes = List<String>.from(data['classes']);
            List<String> subjects = List<String>.from(data['subjects']);

            // Mark each subject as unavailable for each class
            for (var className in classes) {
              for (var subject in subjects) {
                _addUnavailableSubject(school, className, subject);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching unavailable subjects: $e');
      throw e;
    }
  }

  void _addUnavailableSubject(String school, String className, String subject) {
    if (!unavailableSubjectsBySchoolAndClass.containsKey(school)) {
      unavailableSubjectsBySchoolAndClass[school] = {};
    }
    if (!unavailableSubjectsBySchoolAndClass[school]!.containsKey(className)) {
      unavailableSubjectsBySchoolAndClass[school]![className] = [];
    }
    if (!unavailableSubjectsBySchoolAndClass[school]![className]!.contains(
        subject)) {
      unavailableSubjectsBySchoolAndClass[school]![className]!.add(subject);
    }
  }

  Future<void> _checkSavedSelections() async {
    if (currentUserEmail == null) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .doc(currentUserEmail)
          .get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;

        setState(() {
          selectedSchool = data['school'];

          if (data.containsKey('classes')) {
            selectedClasses = List<String>.from(data['classes']);
          }

          if (data.containsKey('subjects')) {
            List<String> subjects = List<String>.from(data['subjects']);
            _reconstructSubjectMapping(subjects);
            isSaved = true;
          }
        });
      }
    } catch (e) {
      print('Error checking saved selections: $e');
      throw e;
    }
  }

  void _reconstructSubjectMapping(List<String> subjects) {
    selectedSubjectsByClass.clear();

    // Initialize empty lists for each selected class
    for (String className in selectedClasses) {
      selectedSubjectsByClass[className] = [];
    }

    // Distribute subjects evenly across classes
    if (subjects.isNotEmpty && selectedClasses.isNotEmpty) {
      int subjectsPerClass = subjects.length ~/ selectedClasses.length;
      int remainder = subjects.length % selectedClasses.length;

      int subjectIndex = 0;
      for (int i = 0; i < selectedClasses.length; i++) {
        String className = selectedClasses[i];
        int subjectsForThisClass = subjectsPerClass + (i < remainder ? 1 : 0);

        for (int j = 0; j < subjectsForThisClass &&
            subjectIndex < subjects.length; j++) {
          selectedSubjectsByClass[className]!.add(subjects[subjectIndex]);
          subjectIndex++;
        }
      }
    }
  }

  // Get total selected subjects count
  int _getTotalSelectedSubjects() {
    return selectedSubjectsByClass.values
        .fold(0, (total, subjects) => total + subjects.length);
  }

  // Get max subjects allowed per class based on number of selected classes
  int _getMaxSubjectsPerClass() {
    return selectedClasses.length == 1 ? 2 : 1;
  }

  // Get available subjects for a specific class
  List<String> _getAvailableSubjectsForClass(String className) {
    if (selectedSchool == null) return [];

    List<String> allSubjects = classSubjects[className] ?? [];
    List<
        String> unavailableSubjects = unavailableSubjectsBySchoolAndClass[selectedSchool]?[className] ??
        [];
    List<String> currentUserSubjects = selectedSubjectsByClass[className] ?? [];

    return allSubjects.where((subject) {
      return !unavailableSubjects.contains(subject) ||
          currentUserSubjects.contains(subject);
    }).toList();
  }

  // Check if a subject is unavailable for a specific class
  bool _isSubjectUnavailableForClass(String className, String subject) {
    if (selectedSchool == null) return false;

    List<String> currentUserSubjects = selectedSubjectsByClass[className] ?? [];
    if (currentUserSubjects.contains(subject)) return false;

    return unavailableSubjectsBySchoolAndClass[selectedSchool]?[className]
        ?.contains(subject) ?? false;
  }

  Future<void> _saveSelection() async {
    if (currentUserEmail == null) {
      _showToast("User not authenticated");
      return;
    }

    // Validation
    if (selectedSchool == null) {
      _showToast("Please select a school first");
      return;
    }

    if (selectedClasses.isEmpty) {
      _showToast("Please select at least one class");
      return;
    }

    int totalSubjects = _getTotalSelectedSubjects();
    if (totalSubjects == 0) {
      _showToast("Please select at least one subject");
      return;
    }

    if (totalSubjects > 2) {
      _showToast("Maximum 2 subjects allowed in total");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Flatten subjects for saving
      List<String> allSelectedSubjects = [];
      selectedSubjectsByClass.forEach((_, subjects) {
        allSelectedSubjects.addAll(subjects);
      });

      await FirebaseFirestore.instance
          .collection('Teachers_Details')
          .doc(currentUserEmail)
          .set({
        'school': selectedSchool,
        'classes': selectedClasses,
        'subjects': allSelectedSubjects,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => isSaved = true);

      _showSuccessSnackBar('Selections saved successfully!');

      // Refresh unavailable subjects after saving
      await _fetchUnavailableSubjects();
    } catch (e) {
      print('Error saving selections: $e');
      _showErrorSnackBar('Error saving selections. Please try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _editSelections() async {
    bool? confirm = await _showConfirmDialog(
      'Edit Selections',
      'Are you sure you want to edit your selections? This will allow you to modify your current choices.',
    );

    if (confirm == true) {
      setState(() => isSaved = false);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Confirm'),
              ),
            ],
          ),
    );
  }

  Widget _buildSchoolSelection() {
    return _buildSection(
      title: 'School Selection',
      icon: Icons.school,
      color: Colors.blue,
      child: isSaved
          ? _buildReadOnlyField(selectedSchool ?? "No school selected")
          : DropdownButtonFormField<String>(
        value: selectedSchool,
        decoration: InputDecoration(
          labelText: 'Select School',
          prefixIcon: Icon(Icons.location_on, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: schools.map((school) =>
            DropdownMenuItem(
              value: school,
              child: Text(school),
            )).toList(),
        onChanged: (value) {
          setState(() {
            selectedSchool = value;
            selectedClasses.clear();
            selectedSubjectsByClass.clear();
          });
        },
      ),
    );
  }

  Widget _buildClassSelection() {
    return _buildSection(
      title: 'Class Selection',
      subtitle: 'Select 1-2 classes • Max 2 subjects total',
      icon: Icons.class_,
      color: Colors.green,
      child: isSaved
          ? _buildReadOnlyField(selectedClasses.join(', '))
          : Wrap(
        spacing: 12,
        runSpacing: 12,
        children: classes.map((className) {
          bool isSelected = selectedClasses.contains(className);
          bool canSelect = selectedClasses.length < 2 || isSelected;

          return _buildSelectableChip(
            label: className,
            isSelected: isSelected,
            canSelect: canSelect && selectedSchool != null,
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedClasses.remove(className);
                  selectedSubjectsByClass.remove(className);
                } else {
                  selectedClasses.add(className);
                  selectedSubjectsByClass[className] = [];
                }
              });
            },
            color: Colors.green,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectSelection() {
    if (selectedClasses.isEmpty || selectedSchool == null) {
      return _buildEmptyState();
    }

    return Column(
      children: selectedClasses.map((className) =>
          _buildSubjectSelectionForClass(className)
      ).toList(),
    );
  }

  Widget _buildSubjectSelectionForClass(String className) {
    List<String> availableSubjects = _getAvailableSubjectsForClass(className);
    List<String> selectedSubjects = selectedSubjectsByClass[className] ?? [];
    int maxSubjectsPerClass = _getMaxSubjectsPerClass();
    int totalSelected = _getTotalSelectedSubjects();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(className, style: TextStyle(color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Subjects (${selectedSubjects.length}/$maxSubjectsPerClass)',
                  style: TextStyle(color: Colors.orange.shade600,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            selectedClasses.length == 1
                ? 'Max 2 subjects for single class'
                : 'Max 1 subject per class (2 classes selected)',
            style: TextStyle(color: Colors.orange.shade600,
                fontSize: 14,
                fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 16),

          if (isSaved)
            _buildReadOnlyField(selectedSubjects.isNotEmpty
                ? selectedSubjects.join(', ')
                : 'No subjects selected')
          else
            if (availableSubjects.isEmpty)
              _buildWarningCard(
                  'All subjects for this class are already assigned')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableSubjects.map((subject) {
                  bool isSelected = selectedSubjects.contains(subject);
                  bool isUnavailable = _isSubjectUnavailableForClass(
                      className, subject);
                  bool canSelect = !isUnavailable &&
                      (isSelected ||
                          (selectedSubjects.length < maxSubjectsPerClass &&
                              totalSelected < 2));

                  return _buildSubjectChip(
                    subject: subject,
                    isSelected: isSelected,
                    isUnavailable: isUnavailable,
                    canSelect: canSelect,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedSubjects.remove(subject);
                        } else {
                          selectedSubjects.add(subject);
                        }
                        selectedSubjectsByClass[className] = selectedSubjects;
                      });
                    },
                  );
                }).toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    if (!isSaved &&
        (selectedClasses.isEmpty || _getTotalSelectedSubjects() == 0)) {
      return SizedBox.shrink();
    }

    return _buildSection(
      title: 'Selection Summary',
      icon: Icons.summarize,
      color: Colors.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Subjects: ${_getTotalSelectedSubjects()}/2',
            style: TextStyle(color: Colors.purple.shade700,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          ...selectedClasses.map((className) {
            List<String> subjects = selectedSubjectsByClass[className] ?? [];
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(className, style: TextStyle(color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subjects.isNotEmpty
                          ? subjects.join(', ')
                          : 'No subjects selected',
                      style: TextStyle(color: Colors.purple.shade700,
                          fontSize: 16),
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

  Widget _buildSection({
    required String title,
    String? subtitle,
    required IconData icon,
    required MaterialColor color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade600, size: 28),
              SizedBox(width: 12),
              Text(title, style: TextStyle(color: color.shade600,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: color.shade600,
                fontSize: 14,
                fontStyle: FontStyle.italic)),
          ],
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: TextStyle(
          color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required bool canSelect,
    required VoidCallback onTap,
    required MaterialColor color,
  }) {
    return InkWell(
      onTap: canSelect ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: canSelect ? color.shade600 : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (canSelect
                ? color.shade600
                : Colors.grey),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectChip({
    required String subject,
    required bool isSelected,
    required bool isUnavailable,
    required bool canSelect,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: canSelect ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.shade600
              : (canSelect ? Colors.white : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.orange.shade600
                : (isUnavailable
                ? Colors.red.shade300
                : (canSelect ? Colors.orange.shade300 : Colors.grey.shade300)),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subject,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isUnavailable
                    ? Colors.red.shade600
                    : (canSelect ? Colors.orange.shade700 : Colors.grey
                    .shade600)),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isUnavailable && !isSelected)
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.lock, size: 14, color: Colors.red.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 48),
          SizedBox(height: 16),
          Text(
            'Please select a school and at least one class first',
            style: TextStyle(color: Colors.grey.shade600,
                fontSize: 18,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red.shade600),
          SizedBox(width: 12),
          Expanded(child: Text(message,
              style: TextStyle(color: Colors.red.shade600, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (isLoading) {
      return Center(
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    int totalSubjects = _getTotalSelectedSubjects();
    bool hasValidSelection = false;

    // Check if selection is complete and valid
    if (selectedClasses.length == 1) {
      // One class selected - should have exactly 2 subjects
      hasValidSelection = totalSubjects == 2;
    } else if (selectedClasses.length == 2) {
      // Two classes selected - should have exactly 2 subjects total (1 per class)
      hasValidSelection = totalSubjects == 2 &&
          selectedSubjectsByClass.values.every((subjects) => subjects.length == 1);
    }

    // If saved and has valid selection, hide buttons completely
    if (isSaved && hasValidSelection) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green.shade300, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
            SizedBox(width: 12),
            Text(
              'Selections Complete',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      );
    }

    // If saved but selection is incomplete, show edit button
    if (isSaved) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade300, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Incomplete Selection',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.orange.shade600,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)
                ),
                padding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: _editSelections,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                      'Edit',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      )
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show save button when not saved
    bool canSave = selectedSchool != null &&
        selectedClasses.isNotEmpty &&
        totalSubjects > 0 &&
        totalSubjects <= 2;

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave ? Colors.blueAccent : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
          ),
          elevation: canSave ? 8 : 2,
        ),
        onPressed: canSave ? _saveSelection : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Save Selections',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Add these methods to your _Class_SelectionState class:

// Missing success and error snackbar methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

// Missing build method - add this as the main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Class & Subject Selection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolSelection(),
            _buildClassSelection(),
            _buildSubjectSelection(),
            _buildSelectionSummary(),
            SizedBox(height: 20),
            _buildActionButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

// Add refresh functionality
  Future<void> _refreshData() async {
    await _initializeData();
  }

// Add pull-to-refresh wrapper (optional enhancement)
  Widget _buildRefreshableBody() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.blueAccent,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSchoolSelection(),
            _buildClassSelection(),
            _buildSubjectSelection(),
            _buildSelectionSummary(),
            SizedBox(height: 20),
            _buildActionButton(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

// Enhanced error handling for network issues
  Future<void> _handleNetworkError(dynamic error) async {
    String errorMessage = 'An error occurred';

    if (error.toString().contains('network')) {
      errorMessage = 'Network error. Please check your connection.';
    } else if (error.toString().contains('permission')) {
      errorMessage = 'Permission denied. Please check your account access.';
    } else if (error.toString().contains('timeout')) {
      errorMessage = 'Request timeout. Please try again.';
    }

    _showErrorSnackBar(errorMessage);
  }

// Add validation helper
  bool _isSelectionValid() {
    if (selectedSchool == null) return false;
    if (selectedClasses.isEmpty) return false;
    int totalSubjects = _getTotalSelectedSubjects();
    return totalSubjects > 0 && totalSubjects <= 2;
  }

// Add clear selections method
  Future<void> _clearSelections() async {
    bool? confirm = await _showConfirmDialog(
      'Clear Selections',
      'Are you sure you want to clear all selections? This action cannot be undone.',
    );

    if (confirm == true) {
      setState(() {
        selectedSchool = null;
        selectedClasses.clear();
        selectedSubjectsByClass.clear();
        isSaved = false;
      });
      _showToast('Selections cleared');
    }
  }

}