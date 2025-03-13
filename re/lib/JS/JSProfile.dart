import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JSProfile extends StatefulWidget {
  @override
  _JSProfileState createState() => _JSProfileState();
}

class _JSProfileState extends State<JSProfile> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String backgroundUrl = '';
  String foregroundUrl = '';
  String name = '';
  String description = '';
  late TabController _tabController;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProfileData(); // Fetch data when widget initializes
  }

  Future<void> _fetchProfileData() async {
    var user = _auth.currentUser;
    if (user == null) return;

    try {
      var doc = await FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        var data = doc.data() ?? {};
        setState(() {
          name = data['Name'] ?? '';
          description = data['Description'] ?? '';
          backgroundUrl = data['background'] ?? '';
          foregroundUrl = data['foreground'] ?? '';
          nameController.text = name;
          descriptionController.text = description;
        });
      } else {
        // Create new profile document with default values
        await FirebaseFirestore.instance
            .collection('JS_Profile')
            .doc(user.uid)
            .set({
              'name': '',
              'description': '',
              'background': '',
              'foreground': '',
              'timeline': [],
              'skills': {
                'proficientIn': [],
                'activelyLearning': [],
                'contributions': []
              },
              'activities': []
            });
        
        // Set default values in state
        setState(() {
          name = '';
          description = '';
          nameController.text = name;
          descriptionController.text = description;
        });
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      // Set default values in case of error
      setState(() {
        name = '';
        description = '';
        nameController.text = name;
        descriptionController.text = description;
      });
    }
  }

  // Update Timeline
  Future<void> _addTimelineEntry(String year, String description) async {
    var user = _auth.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(user.uid)
          .set({
            'timeline': FieldValue.arrayUnion([
              {
                'year': year,
                'description': description,
                'timestamp': DateTime.now().toIso8601String(),
              }
            ])
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error adding timeline entry: $e");
      throw e;
    }
  }

  // Update Skills
  Future<void> _addSkill(String category, String skill) async {
    var user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(user.uid);

      // Get the current document
      DocumentSnapshot doc = await docRef.get();
      
      // Initialize an empty skills map if document doesn't exist
      if (!doc.exists) {
        await docRef.set({
          'skills': {
            'proficientIn': [],
            'activelyLearning': [],
            'contributions': []
          }
        }, SetOptions(merge: true));
        doc = await docRef.get(); // Get updated document
      }

      // Safely get the data
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final skills = data['skills'] as Map<String, dynamic>? ?? {};
      final categorySkills = (skills[category] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

      // Add the new skill if it's not already present
      if (!categorySkills.contains(skill)) {
        categorySkills.add(skill);
        
        // Update only the specific category
        await docRef.update({
          'skills.$category': categorySkills
        });
      }
    } catch (e) {
      print("Error adding skill: $e");
      throw e;
    }
  }

  // Update Activities
  Future<void> _addActivity(String companyName, String title, String description) async {
    var user = _auth.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(user.uid)
          .set({
            'activities': FieldValue.arrayUnion([
              {
                'companyName': companyName,
                'title': title,
                'description': description,
                'timestamp': DateTime.now().toIso8601String(),
              }
            ])
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error adding activity: $e");
      throw e;
    }
  }

  // Build Timeline UI without box
  Widget _buildTimeline() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(_auth.currentUser?.uid ?? '')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var timeline = (data['timeline'] as List?) ?? [];

        return ListView.builder(
          itemCount: timeline.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            var item = timeline[index] as Map<String, dynamic>;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vertical line with dot
                  Container(
                    width: 20,
                    margin: EdgeInsets.only(right: 16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.blue[900],
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue[900]!,
                              width: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Year and Description Column
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['year']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('JS_Profile')
                                      .doc(_auth.currentUser?.uid ?? '')
                                      .update({
                                        'timeline': FieldValue.arrayRemove([item])
                                      });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            item['description']?.toString() ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Build Skills UI with proper data fetching
  Widget _buildSkills() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(_auth.currentUser?.uid ?? '')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final skills = data['skills'] as Map<String, dynamic>? ?? {};

        return ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            _buildSkillSection(
              'proficientIn', 
              'Proficient In', 
              (skills['proficientIn'] as List<dynamic>? ?? []).map((e) => e.toString()).toList()
            ),
            SizedBox(height: 16),
            _buildSkillSection(
              'activelyLearning', 
              'Actively Learning', 
              (skills['activelyLearning'] as List<dynamic>? ?? []).map((e) => e.toString()).toList()
            ),
            SizedBox(height: 16),
            _buildSkillSection(
              'contributions', 
              'Contributions', 
              (skills['contributions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList()
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillSection(String category, String title, List<String> skills) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showSkillsForm(category),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (skills.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No skills added yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: skills.map((skill) => Chip(
                  label: Text(skill),
                  deleteIcon: Icon(Icons.close, size: 18),
                  onDeleted: () => _deleteSkill(category, skill),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Update the skills form dialog to close after saving
  void _showSkillsForm(String category) {
    TextEditingController skillController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Skill"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skillController,
                decoration: InputDecoration(
                  labelText: "Enter Skill",
                  hintText: "e.g., Python, JavaScript, React",
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (value) async {
                  if (value.trim().isNotEmpty) {
                    try {
                      await _addSkill(category, value.trim());
                      Navigator.pop(context); // Close dialog on success
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Skill added successfully")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add skill. Please try again.")),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (skillController.text.trim().isNotEmpty) {
                  try {
                    await _addSkill(category, skillController.text.trim());
                    Navigator.pop(context); // Close dialog on success
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Skill added successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add skill. Please try again.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a skill")),
                  );
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Show Activities Form Dialog
  void _showActivitiesForm() {
    TextEditingController companyController = TextEditingController();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Activity"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: companyController,
                  decoration: InputDecoration(
                    labelText: "Company Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (companyController.text.isNotEmpty && 
                    titleController.text.isNotEmpty && 
                    descriptionController.text.isNotEmpty) {
                  try {
                    await _addActivity(
                      companyController.text,
                      titleController.text,
                      descriptionController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Activity added successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add activity. Please try again.")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill all fields")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Update the Activities UI
  Widget _buildActivities() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(_auth.currentUser?.uid ?? '')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var activities = (data['activities'] as List?) ?? [];

        return ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            var activity = activities[index] as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['companyName'] ?? '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      activity['title'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(activity['description'] ?? ''),
                    ButtonBar(
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('JS_Profile')
                                .doc(_auth.currentUser?.uid ?? '')
                                .update({
                                  'activities': FieldValue.arrayRemove([activity])
                                });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDeleteDialog(String type, [String? docId]) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit or Delete $type"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Do you want to edit or delete this $type?"),
            ],
          ),
          actions: [
            // Edit Option
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _showEditForm(type, docId!); // Show the edit form
              },
              child: Text("Edit"),
            ),
            // Delete Option
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog

                // Perform delete action
                if (type == 'Timeline') {
                  await FirebaseFirestore.instance.collection("JS_Timeline")
                      .doc(docId)
                      .delete();
                } else if (type == 'Skills') {
                  await FirebaseFirestore.instance.collection("JS_Skills").doc(
                      docId).delete();
                } else if (type == 'Activities') {
                  await FirebaseFirestore.instance.collection("JS_Activities")
                      .doc(docId)
                      .delete();
                }
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // Show Add form for Timeline, Skills, or Activities
  void _showAddForm() {
    int activeTab = _tabController.index;
    if (activeTab == 1) {
      _showSkillsForm('proficientIn');
    } else if (activeTab == 0) {
      _showTimelineForm();
    } else {
      _showActivitiesForm();
    }
  }

  // Timeline Form
  void _showTimelineForm() {
    TextEditingController yearController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Timeline Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: yearController,
                decoration: InputDecoration(
                  labelText: "Year",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (yearController.text.isNotEmpty && 
                      descriptionController.text.isNotEmpty) {
                    await _addTimelineEntry(
                      yearController.text,
                      descriptionController.text
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Timeline entry added successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill all fields")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to add entry. Please try again.")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String field, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit "),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Enter",
              border: OutlineInputBorder(),
            ),
            maxLines: field == 'description' ? 3 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (controller.text.trim().isNotEmpty) {
                    // Update Firestore
                    await FirebaseFirestore.instance
                        .collection('JS_Profile')
                        .doc(_auth.currentUser?.uid ?? '')
                        .set({
                          field: controller.text.trim(),
                        }, SetOptions(merge: true));
                    
                    // Update local state
                    setState(() {
                      if (field == 'name') {
                        name = controller.text.trim();
                      } else if (field == 'description') {
                        description = controller.text.trim();
                      }
                    });

                    // Close dialog
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$field updated successfully")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter a value")),
                    );
                  }
                } catch (e) {
                  print("Error updating $field: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update $field. Please try again.")),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("JS Profile"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Timeline"),
            Tab(text: "Skills"),
            Tab(text: "Activities"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                backgroundUrl.isNotEmpty
                    ? Image.network(backgroundUrl, fit: BoxFit.cover,
                    height: 200,
                    width: double.infinity)
                    : Container(height: 200, color: Colors.grey),
                Positioned(
                  bottom: 10,
                  child: GestureDetector(
                    onLongPress: () => _showEditDeleteDialog('Profile Image'),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: foregroundUrl.isNotEmpty ? NetworkImage(
                          foregroundUrl) : null,
                      child: foregroundUrl.isEmpty
                          ? Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog('Name', nameController);
                  },
                ),
                Text(name, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog('Description', descriptionController);
                  },
                ),
                Text(description),
              ],
            ),
            SizedBox(height: 20),
            Container(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimeline(),
                  _buildSkills(),
                  _buildActivities(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddForm,
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteSkill(String category, String skill) async {
    var user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('JS_Profile')
          .doc(user.uid);

      DocumentSnapshot doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final skills = data['skills'] as Map<String, dynamic>? ?? {};
      final categorySkills = (skills[category] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
      
      // Remove the skill
      categorySkills.remove(skill);
      
      // Update only the specific category
      await docRef.update({
        'skills.$category': categorySkills
      });
    } catch (e) {
      print("Error deleting skill: $e");
      throw e;
    }
  }

  void _showEditForm(String type, String docId) {
    TextEditingController yearController = TextEditingController();
    TextEditingController achievementController = TextEditingController();
    TextEditingController skillDescriptionController = TextEditingController();
    TextEditingController proficientInController = TextEditingController();
    TextEditingController activelyLearningController = TextEditingController();
    TextEditingController contributionsController = TextEditingController();
    TextEditingController companyNameController = TextEditingController();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $type"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'Timeline') ...[
                  // Timeline Edit Form
                  TextField(
                    controller: yearController,
                    decoration: InputDecoration(labelText: "Year"),
                  ),
                  TextField(
                    controller: achievementController,
                    decoration: InputDecoration(labelText: "Achievement"),
                  ),
                ] else
                  if (type == 'Skills') ...[
                    // Skills Edit Form
                    ListTile(
                      title: Text('Proficient In'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _showSkillsForm('proficientIn');
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Actively Learning'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _showSkillsForm('activelyLearning');
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Contributions'),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _showSkillsForm('contributions');
                        },
                      ),
                    ),
                  ] else
                    if (type == 'Activities') ...[
                      // Activities Edit Form
                      TextField(
                        controller: companyNameController,
                        decoration: InputDecoration(labelText: "Company Name"),
                      ),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: "Title"),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(labelText: "Description"),
                      ),
                    ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save the changes to Firestore based on the type
                if (type == 'Timeline') {
                  await _addTimelineEntry(yearController.text, achievementController.text);
                } else if (type == 'Skills') {
                  await FirebaseFirestore.instance.collection("JS_Skills").doc(
                      docId).update({
                    'description': skillDescriptionController.text,
                    'proficientIn': proficientInController.text,
                    'activelyLearning': activelyLearningController.text,
                    'contribution': contributionsController.text,
                  });
                } else if (type == 'Activities') {
                  await _addActivity(companyNameController.text, titleController.text, descriptionController.text);
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

}