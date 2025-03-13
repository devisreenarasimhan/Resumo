import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Add this extension before the class declaration
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

void main() {
  runApp(MaterialApp(
    home: ProfileRC(),
    debugShowCheckedModeBanner: false,
  ));
}

class ProfileRC extends StatefulWidget {
  @override
  _ProfileRCState createState() => _ProfileRCState();
}

class _ProfileRCState extends State<ProfileRC> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? currentUser;
  String backgroundUrl = '';
  String foregroundUrl = '';
  String companyName = "Your Name";
  String description = "Company Description";
  late TabController _tabController;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  List<String> eventTags = [];
  List<String> openingTags = [];
  List<Map<String, dynamic>> _myOpenings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      _fetchProfileData();
    }
    _tabController = TabController(length: 3, vsync: this);
    _fetchMyOpenings();
  }

  Future<void> _fetchProfileData() async {
    if (currentUser == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('RC_Profile')
        .doc(currentUser!.uid)
        .get();

    if (doc.exists) {
      var data = doc.data() ?? {};
      setState(() {
        companyName = data['name'] ?? 'Your Name';
        description = data['description'] ?? 'Company Description';
        backgroundUrl = data['background'] ?? '';
        foregroundUrl = data['foreground'] ?? '';
        nameController.text = companyName;
        descriptionController.text = description;
      });
    } else {
      // Create new profile document with initial arrays
      await FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .set({
        'name': companyName,
        'description': description,
        'background': '',
        'foreground': '',
        'about': [],
        'events': [],
        'openings': []
      });
    }
  }

  // Update About section
  Future<void> _updateAboutSection(String field, String value) async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('RC_Profile')
        .doc(currentUser!.uid)
        .update({
      'about.$field': value,
    });
  }

  // About entries methods
  Future<void> _addAboutEntry(String text) async {
    if (currentUser == null) return;

    try {
      Map<String, dynamic> entry = {
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .update({
        'about': FieldValue.arrayUnion([entry])
      });
    } catch (e) {
      print("Error adding about entry: $e");
      throw e;
    }
  }

  // Events section methods
  Future<void> _addEvent(String companyName, String title, String description, String location, List<String> tags) async {
    if (currentUser == null) return;

    try {
      Map<String, dynamic> event = {
        'companyName': companyName,
        'title': title,
        'description': description,
        'location': location,
        'tags': tags.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .update({
        'events': FieldValue.arrayUnion([event])
      });
    } catch (e) {
      print("Error adding event: $e");
    }
  }

  // Openings section methods
  Future<void> _addOpening(String companyName, String title, String description, String location, List<String> tags) async {
    if (currentUser == null) return;

    try {
      Map<String, dynamic> opening = {
        'companyName': companyName,
        'title': title,
        'description': description,
        'location': location,
        'tags': tags.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .update({
        'openings': FieldValue.arrayUnion([opening])
      });
    } catch (e) {
      print("Error adding opening: $e");
    }
  }

  // Build Profile Header
  Widget _buildProfileHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Background Image
                Container(
                  height: 200,
                  width: double.infinity,
                  child: data['background']?.isNotEmpty == true
                      ? Image.network(data['background'], fit: BoxFit.cover)
                      : Container(color: Colors.grey),
                ),
                // Foreground Image (Profile Picture)
                Positioned(
                  bottom: 10,
                  child: GestureDetector(
                    onTap: () => _uploadImage(false),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: data['foreground']?.isNotEmpty == true
                          ? NetworkImage(data['foreground'])
                          : null,
                      child: data['foreground']?.isEmpty == true
                          ? Icon(Icons.camera_alt)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Company Name with edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['name'] ?? 'Your Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: _showEditNameDialog,
                ),
              ],
            ),
            // Description with pencil icon next to it
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    data['description'] ?? 'Company Description',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditDialog('description', descriptionController),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Build About UI
  Widget _buildAbout() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var aboutEntries = List<Map<String, dynamic>>.from(data['about'] ?? []);

        if (aboutEntries.isEmpty) {
          return Center(
            child: Text('No about entries yet. Click + to add one.'),
          );
        }

        return ListView.builder(
          itemCount: aboutEntries.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            var entry = aboutEntries[index];
            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: ListTile(
                title: Text(entry['text'] ?? ''),
                subtitle: entry['timestamp'] != null
                    ? Text(entry['timestamp'])
                    : null,
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('RC_Profile')
                        .doc(currentUser!.uid)
                        .update({
                      'about': FieldValue.arrayRemove([entry])
                    });
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build Events UI
  Widget _buildEvents() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var events = List<Map<String, dynamic>>.from(data['events'] ?? []);

        if (events.isEmpty) {
          return Center(
            child: Text('No events yet. Click + to add one.'),
          );
        }

        return ListView.builder(
          itemCount: events.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            var event = events[index];
            List<String> tags = [];
            if (event['tags'] != null) {
              if (event['tags'] is List) {
                tags = List<String>.from(event['tags']);
              } else if (event['tags'] is String) {
                tags = [event['tags'] as String];
              }
            }

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.business, size: 20, color: Colors.grey[700]),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(event['companyName'] ?? ''),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showEditDialog('events', TextEditingController()),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('RC_Profile')
                                    .doc(currentUser!.uid)
                                    .update({
                                  'events': FieldValue.arrayRemove([event])
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(event['description'] ?? ''),
                    if (event['location'] != null && event['location'].isNotEmpty) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 4),
                          Text(event['location']),
                        ],
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: tags.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(color: Colors.blue[900]),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build Openings UI
  Widget _buildOpenings() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        var openings = List<Map<String, dynamic>>.from(data['openings'] ?? []);

        if (openings.isEmpty) {
          return Center(
            child: Text('No openings yet. Click + to add one.'),
          );
        }

        return ListView.builder(
          itemCount: openings.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            var opening = openings[index];
            List<String> tags = [];
            if (opening['tags'] != null) {
              if (opening['tags'] is List) {
                tags = List<String>.from(opening['tags']);
              } else if (opening['tags'] is String) {
                tags = [opening['tags'] as String];
              }
            }

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.business, size: 20, color: Colors.grey[700]),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      opening['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(opening['companyName'] ?? ''),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showEditDialog('openings', TextEditingController()),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('RC_Profile')
                                    .doc(currentUser!.uid)
                                    .update({
                                  'openings': FieldValue.arrayRemove([opening])
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(opening['description'] ?? ''),
                    if (opening['location'] != null && opening['location'].isNotEmpty) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16),
                          SizedBox(width: 4),
                          Text(opening['location']),
                        ],
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: tags.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(color: Colors.blue[900]),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------
  // Edit / Delete Dialog Function
  // ----------------------------
  void _showEditDeleteDialog(String type, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit or Delete $type"),
          content: Text("Do you want to edit or delete this $type entry?"),
          actions: [
            // Edit option
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditForm(type, docId);
              },
              child: Text("Edit"),
            ),
            // Delete option
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (type == 'Events') {
                  await FirebaseFirestore.instance.collection("RC_Events").doc(docId).delete();
                } else if (type == 'Openings') {
                  await FirebaseFirestore.instance.collection("RC_Openings").doc(docId).delete();
                } else if (type == 'About') {
                  await FirebaseFirestore.instance.collection("RC_About").doc(docId).delete();
                }
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------
  // Image Upload & Crop Functions
  // ----------------------------
  Future<void> _uploadImage(bool isBackground) async {
    if (currentUser == null) return;

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File? croppedFile = await _cropImage(File(pickedFile.path));
    if (croppedFile == null) return;

    String fileName = isBackground ? 'background' : 'foreground';
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('RC_imgs/${currentUser!.uid}_${fileName}.jpg');

    await storageRef.putFile(croppedFile);
    String downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('RC_Profile')
        .doc(currentUser!.uid)
        .set(
      {fileName: downloadUrl},
      SetOptions(merge: true),
    );

    setState(() {
      if (isBackground) {
        backgroundUrl = downloadUrl;
      } else {
        foregroundUrl = downloadUrl;
      }
    });
  }

  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  // ----------------------------
  // Add Entry Forms (for About, Events, Openings)
  // ----------------------------
  void _showAddForm() {
    int activeTab = _tabController.index;
    if (activeTab == 0) {
      TextEditingController textController = TextEditingController();
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text("Add About Entry"),
            content: TextField(
              controller: textController,
              decoration: InputDecoration(labelText: "About Text"),
              maxLines: null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  if (textController.text.isNotEmpty) {
                    try {
                      await _addAboutEntry(textController.text);
                      Navigator.pop(dialogContext);
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text("Failed to add entry. Please try again.")),
                      );
                    }
                  }
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      );
    } else if (activeTab == 1) {
      _showEventForm();
    } else if (activeTab == 2) {
      _showOpeningForm();
    }
  }

  void _showEventForm() {
    TextEditingController companyNameController = TextEditingController();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add New Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      maxLines: 3,
                    ),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(labelText: "Location"),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: [
                        ActionChip(
                          label: Text("Add Tag"),
                          onPressed: () async {
                            String? tag = await _showTagDialog();
                            if (tag != null && tag.isNotEmpty) {
                              setState(() {
                                selectedTags.add(tag);
                              });
                            }
                          },
                        ),
                        ...selectedTags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() {
                              selectedTags.remove(tag);
                            });
                          },
                        )).toList(),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      Map<String, dynamic> event = {
                        'companyName': companyNameController.text,
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'location': locationController.text,
                        'tags': selectedTags,
                        'timestamp': DateTime.now().toIso8601String(),
                      };

                      await FirebaseFirestore.instance
                          .collection('RC_Profile')
                          .doc(currentUser!.uid)
                          .update({
                        'events': FieldValue.arrayUnion([event])
                      });

                      Navigator.pop(dialogContext);
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text("Failed to add event. Please try again.")),
                      );
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOpeningForm() {
    TextEditingController companyNameController = TextEditingController();
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController locationController = TextEditingController();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add New Opening"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      maxLines: 3,
                    ),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(labelText: "Location"),
                    ),
                    SizedBox(height: 10),
                    // Tags section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tags",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ActionChip(
                              label: Text("Add Tag"),
                              onPressed: () async {
                                String? tag = await _showTagDialog();
                                if (tag != null && tag.isNotEmpty) {
                                  setState(() {
                                    selectedTags.add(tag);
                                  });
                                }
                              },
                            ),
                            ...selectedTags.map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  selectedTags.remove(tag);
                                });
                              },
                              backgroundColor: Colors.blue[50],
                              labelStyle: TextStyle(color: Colors.blue[900]),
                            )).toList(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (companyNameController.text.isEmpty ||
                        titleController.text.isEmpty ||
                        descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text("Please fill in all required fields")),
                      );
                      return;
                    }
                    try {
                      await _addOpening(
                        companyNameController.text,
                        titleController.text,
                        descriptionController.text,
                        locationController.text,
                        selectedTags,
                      );
                      Navigator.pop(dialogContext);
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text("Failed to add opening. Please try again.")),
                      );
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------
  // Edit Entry Form (for About, Events, Openings)
  // ----------------------------
  void _showEditForm(String type, String docId) {
    if (type == 'About') {
      TextEditingController _editAboutController = TextEditingController();
      FirebaseFirestore.instance.collection("RC_About").doc(docId).get().then((doc) {
        if (doc.exists) {
          _editAboutController.text = doc.data()?['text'] ?? '';
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Edit About Entry"),
                content: TextField(
                  controller: _editAboutController,
                  decoration: InputDecoration(labelText: "About Text"),
                  maxLines: null,
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection("RC_About").doc(docId).update({
                        "text": _editAboutController.text,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Save"),
                  ),
                ],
              );
            },
          );
        }
      });
    } else if (type == 'Events') {
      TextEditingController companyNameController = TextEditingController();
      TextEditingController titleController = TextEditingController();
      TextEditingController eventDescriptionController = TextEditingController();

      FirebaseFirestore.instance.collection("RC_Events").doc(docId).get().then((doc) {
        if (doc.exists) {
          var data = doc.data()!;
          companyNameController.text = data['companyName'] ?? '';
          titleController.text = data['title'] ?? '';
          eventDescriptionController.text = data['description'] ?? '';
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Edit Event"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: companyNameController,
                        decoration: InputDecoration(labelText: "Company Name"),
                      ),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: "Title"),
                      ),
                      TextField(
                        controller: eventDescriptionController,
                        decoration: InputDecoration(labelText: "Description"),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection("RC_Events").doc(docId).update({
                        "companyName": companyNameController.text,
                        "title": titleController.text,
                        "description": eventDescriptionController.text,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Save"),
                  ),
                ],
              );
            },
          );
        }
      });
    } else if (type == 'Openings') {
      TextEditingController companyNameController = TextEditingController();
      TextEditingController titleController = TextEditingController();
      TextEditingController openingDescriptionController = TextEditingController();

      FirebaseFirestore.instance.collection("RC_Openings").doc(docId).get().then((doc) {
        if (doc.exists) {
          var data = doc.data()!;
          companyNameController.text = data['companyName'] ?? '';
          titleController.text = data['title'] ?? '';
          openingDescriptionController.text = data['description'] ?? '';
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Edit Opening"),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: companyNameController,
                        decoration: InputDecoration(labelText: "Company Name"),
                      ),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(labelText: "Title"),
                      ),
                      TextField(
                        controller: openingDescriptionController,
                        decoration: InputDecoration(labelText: "Description"),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection("RC_Openings").doc(docId).update({
                        "companyName": companyNameController.text,
                        "title": titleController.text,
                        "description": openingDescriptionController.text,
                        "timestamp": DateTime.now().toIso8601String(),
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Save"),
                  ),
                ],
              );
            },
          );
        }
      });
    }
  }

  void _showEditDialog(String field, TextEditingController controller) {
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: field.capitalize(),
                      ),
                      maxLines: field == 'description' ? 3 : 1,
                    ),
                    if (field == 'events' || field == 'openings') ...[
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: selectedTags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() {
                              selectedTags.remove(tag);
                            });
                          },
                        )).toList(),
                      ),
                      TextButton(
                        onPressed: () async {
                          final newTag = await _showTagDialog();
                          if (newTag != null) {
                            setState(() {
                              selectedTags.add(newTag);
                            });
                          }
                        },
                        child: Text("Add Tag"),
                      ),
                    ],
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
                    if (controller.text.isNotEmpty) {
                      try {
                        if (field == 'events' || field == 'openings') {
                          // Handle events and openings differently
                          await _addEvent(
                            companyName,
                            controller.text,
                            'Description',
                            'Location',
                            selectedTags,
                          );
                        } else {
                          // Handle regular fields
                          await FirebaseFirestore.instance
                              .collection('RC_Profile')
                              .doc(currentUser!.uid)
                              .update({field: controller.text});
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Updated successfully')),
                        );
                      } catch (e) {
                        print("Error updating: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update')),
                        );
                      }
                    }
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showTagDialog() async {
    TextEditingController tagController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Tag"),
          content: TextField(
            controller: tagController,
            decoration: InputDecoration(
              labelText: "Tag Name",
              hintText: "Enter tag name",
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (tagController.text.isNotEmpty) {
                  Navigator.pop(context, tagController.text.trim());
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // Add method to update company name
  Future<void> _updateCompanyName(String newName) async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('RC_Profile')
          .doc(currentUser!.uid)
          .update({
        'name': newName,
      });

      setState(() {
        companyName = newName;
      });

      // Update the display name in Firebase Auth
      await currentUser!.updateDisplayName(newName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      print('Error updating name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name')),
      );
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _updateCompanyName(nameController.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchMyOpenings() async {
    setState(() => _isLoading = true);
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Fetch openings posted by current recruiter
      final openingsSnapshot = await _firestore
          .collection('openings')
          .where('recruiterId', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> openings = [];

      for (var doc in openingsSnapshot.docs) {
        Map<String, dynamic> openingData = doc.data();
        openingData['id'] = doc.id;

        // Fetch applications for this opening
        final applicationsDoc = await _firestore
            .collection('opening_applied')
            .doc(doc.id)
            .get();

        if (applicationsDoc.exists) {
          openingData['applications'] = applicationsDoc.data()?['applied_users'] ?? [];
          openingData['applicationCount'] = applicationsDoc.data()?['count'] ?? 0;
        } else {
          openingData['applications'] = [];
          openingData['applicationCount'] = 0;
        }

        openings.add(openingData);
      }

      setState(() {
        _myOpenings = openings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching openings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCandidateStatus(
      String openingId,
      Map<String, dynamic> candidate,
      String status
      ) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Update or create status document
      await _firestore.collection('JC_Status').doc('${openingId}_${candidate['email']}').set({
        'openingId': openingId,
        'candidateEmail': candidate['email'],
        'candidateName': candidate['name'],
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.email,
        'openingTitle': _myOpenings.firstWhere((o) => o['id'] == openingId)['title'],
        'companyName': _myOpenings.firstWhere((o) => o['id'] == openingId)['companyName'],
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Candidate ${candidate['name']} marked as $status'),
          backgroundColor: _getStatusColor(status),
        ),
      );
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'shortlisted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showApplicants(Map<String, dynamic> opening) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(opening['title']),
            Text(
              opening['companyName'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Applications: ${opening['applicationCount']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 16),
              if (opening['applications'].isEmpty)
                Text('No applications yet')
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: opening['applications'].length,
                    itemBuilder: (context, index) {
                      final candidate = opening['applications'][index];
                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore
                            .collection('JC_Status')
                            .doc('${opening['id']}_${candidate['email']}')
                            .get(),
                        builder: (context, snapshot) {
                          String currentStatus = 'pending';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            currentStatus = snapshot.data!.get('status');
                          }

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(currentStatus).withOpacity(0.2),
                                child: Icon(Icons.person,
                                    color: _getStatusColor(currentStatus)
                                ),
                              ),
                              title: Text(candidate['name'] ?? 'Anonymous'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(candidate['email'] ?? ''),
                                  SizedBox(height: 4),
                                  Text(
                                    'Status: ${currentStatus.toUpperCase()}',
                                    style: TextStyle(
                                      color: _getStatusColor(currentStatus),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.check_circle_outline),
                                    color: Colors.green,
                                    onPressed: () => _updateCandidateStatus(
                                        opening['id'],
                                        candidate,
                                        'accepted'
                                    ),
                                    tooltip: 'Accept',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.access_time),
                                    color: Colors.orange,
                                    onPressed: () => _updateCandidateStatus(
                                        opening['id'],
                                        candidate,
                                        'shortlisted'
                                    ),
                                    tooltip: 'Shortlist',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_outlined),
                                    color: Colors.red,
                                    onPressed: () => _updateCandidateStatus(
                                        opening['id'],
                                        candidate,
                                        'rejected'
                                    ),
                                    tooltip: 'Reject',
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PROFILE"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "About"),
            Tab(text: "Events"),
            Tab(text: "Openings"),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              Container(
                height: MediaQuery.of(context).size.height - 300,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAbout(),
                    _buildEvents(),
                    _buildOpenings(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddForm,
        child: Icon(Icons.add),
      ),
    );
  }
}
