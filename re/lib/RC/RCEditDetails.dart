import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:re/RC/RCHome.dart';
import '/JS/Home.dart';

class RCEditDetailsPage extends StatefulWidget {
  const RCEditDetailsPage({Key? key}) : super(key: key);

  @override
  State<RCEditDetailsPage> createState() => _RCEditDetailsPageState();
}

class _RCEditDetailsPageState extends State<RCEditDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController extraController = TextEditingController();
  final TextEditingController skillController = TextEditingController();
  bool isDM = false;
  List<String> selectedSkills = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // Load existing data if available
  Future<void> _loadExistingData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Load profile data
        final profileDoc = await FirebaseFirestore.instance
            .collection('RC_Profile')
            .doc(user.uid)
            .get();

        if (profileDoc.exists) {
          final data = profileDoc.data();
          setState(() {
            nameController.text = data?['name'] ?? '';
            roleController.text = data?['role'] ?? '';
            educationController.text = data?['education'] ?? '';
            extraController.text = data?['extra'] ?? '';
            isDM = data?['isDM'] ?? false;
          });
        }

        // Load tags
        final tagsDoc = await FirebaseFirestore.instance
            .collection('RC_tags')
            .doc(user.uid)
            .get();

        if (tagsDoc.exists) {
          setState(() {
            selectedSkills = List<String>.from(tagsDoc.data()?['tags'] ?? []);
          });
        }
      } catch (e) {
        print('Error loading data: $e');
      }
    }
  }

  Future<void> addSkill(String skill) async {
    if (skill.isNotEmpty) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          selectedSkills.add(skill);
          skillController.clear();
        });
        await FirebaseFirestore.instance.collection('RC_tags').doc(user.uid).set({
          'tags': selectedSkills
        });
      }
    }
  }

  Future<void> _saveDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save profile details
        await FirebaseFirestore.instance
            .collection('RC_Profile')
            .doc(user.uid)
            .set({
          'name': nameController.text,
          'role': roleController.text,
          'education': educationController.text,
          'extra': extraController.text,
          'isDM': isDM,
          'events': [], // Initialize empty arrays if they don't exist
          'openings': [],
        }, SetOptions(merge: true));

        // Save tags
        await FirebaseFirestore.instance
            .collection('RC_tags')
            .doc(user.uid)
            .set({
          'tags': selectedSkills
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RCHome()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "RESUMO",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "EDIT YOUR DETAILS",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              buildTextField("NAME", nameController),
              buildTextField("ROLE DESIRED", roleController),
              const SizedBox(height: 10),
              const Text("SKILLS DESIRED", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: skillController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.grey),
                    onPressed: () => addSkill(skillController.text),
                  ),
                ),
                onSubmitted: (value) => addSkill(value),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedSkills.map((skill) {
                  return Chip(
                    label: Text(skill),
                    backgroundColor: Colors.brown.shade300,
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              buildTextField("EDUCATION", educationController),
              buildTextField("EXTRA INFORMATION", extraController, maxLines: 3),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: isDM,
                    onChanged: (bool? value) {
                      setState(() {
                        isDM = value ?? false;
                      });
                    },
                  ),
                  const Text("DM"),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                        ),
                        child: const Text("Proceed",
                            style: TextStyle(color: Colors.white)),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.edit, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
