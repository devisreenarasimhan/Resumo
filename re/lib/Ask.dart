import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:re/JS/DocumentsPage.dart';
import 'package:re/RC/RCEditDetails.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Ask());
}

class Ask extends StatelessWidget {
  const Ask({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const UserSelectionScreen(),
    );
  }
}

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  bool isJobSeeker = false;
  bool isRecruiter = false;
  String? filePath;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to pick file
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
      });
    }
  }

  // Method to save user data to Firestore
  Future<void> saveUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'userType': isJobSeeker ? 'Job Seeker' : 'Recruiter',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User data saved successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving data: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "RESUMO",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "WELCOME TO RESUMO\nYOUR JOB SEEKING APPLICATION",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "You are...\nTell us about yourself",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 30),

            // Job-seeker Checkbox
            CheckboxListTile(
              title: const Text("Job-seeker"),
              subtitle: isJobSeeker
                  ? _infoBox(
                  "You are actively searching for employment opportunities to match your skills, qualifications, and career goals.")
                  : null,
              value: isJobSeeker,
              onChanged: (bool? value) {
                setState(() {
                  isJobSeeker = value ?? false;
                  if (isJobSeeker) isRecruiter = false; // Uncheck Recruiter
                });
              },
              activeColor: Colors.brown,
              contentPadding: EdgeInsets.zero,
            ),

            // Recruiter Checkbox
            CheckboxListTile(
              title: const Text("Recruiter"),
              subtitle: isRecruiter
                  ? _infoBox(
                  "You are a professional responsible for identifying, attracting, and hiring qualified candidates for job openings within an organization.")
                  : null,
              value: isRecruiter,
              onChanged: (bool? value) {
                setState(() {
                  isRecruiter = value ?? false;
                  if (isRecruiter) isJobSeeker = false; // Uncheck Job-Seeker
                });
              },
              activeColor: Colors.brown,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 20),

            if (filePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text("Selected file: $filePath"),
              ),

            const Spacer(),

            // Proceed Button
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (isJobSeeker) {
                      // Save user data to Firestore
                      await saveUserData();

                      // Navigate to DocumentsPage
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DocumentsPage(),
                        ),
                      );
                    } else if (isRecruiter) {
                      await saveUserData();

                      // Navigate to DocumentsPage
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RCEditDetailsPage(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select an option to proceed."),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Proceed",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Information Box Widget
Widget _infoBox(String text) {
  return Container(
    padding: const EdgeInsets.all(8),
    margin: const EdgeInsets.only(top: 5),
    decoration: BoxDecoration(
      color: Colors.yellow[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14),
    ),
  );
}
