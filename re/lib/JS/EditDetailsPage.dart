import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Home.dart';

class EditDetailsPage extends StatefulWidget {
  const EditDetailsPage({Key? key}) : super(key: key);

  @override
  State<EditDetailsPage> createState() => _EditDetailsPageState();
}

class _EditDetailsPageState extends State<EditDetailsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController extraController = TextEditingController();
  bool isDM = false;
  List<String> selectedSkills = [];

  @override
  void initState() {
    super.initState();
    fetchUserTags();
  }

  Future<void> fetchUserTags() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('user_tags')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        List<String> tags = List<String>.from(data['tags'] ?? []);
        setState(() {
          selectedSkills = tags.take(10).toList();
          nameController.text = data['name'] ?? '';
          roleController.text = data['role'] ?? '';
          educationController.text = data['education'] ?? '';
          extraController.text = data['extra'] ?? '';
          isDM = data['isDM'] ?? false;
        });
      }
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
              const Text("SKILLS", style: TextStyle(fontWeight: FontWeight.bold)),
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
              buildTextField("EXTRA", extraController, maxLines: 3),
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
                child: ElevatedButton(
                  onPressed: () async {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      // Save all details to user_tags collection
                      await FirebaseFirestore.instance
                          .collection('user_tags')
                          .doc(user.uid)
                          .set({
                            'tags': selectedSkills,
                            'name': nameController.text,
                            'role': roleController.text,
                            'education': educationController.text,
                            'extra': extraController.text,
                            'isDM': isDM,
                            'customUserId': user.uid, // Adding customUserId for verification
                            'email': user.email, // Adding email for verification
                          }, SetOptions(merge: true));

                      // Navigate to the home screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Home()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text("Proceed", style: TextStyle(color: Colors.white)),
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
