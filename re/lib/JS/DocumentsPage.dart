import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'EditDetailsPage.dart';
import 'dart:io';
import 'home.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String? selectedFileName;
  File? selectedFile;
  bool isPrivate = false;
  List<String> skills = [];
  List<String> selectedSkills = [];
  bool isProcessing = false;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      setState(() {
        selectedFileName = result.files.first.name;
        selectedFile = file;
      });
    }
  }

  Future<void> uploadFile(File file) async {
    setState(() => isProcessing = true);

    var request = http.MultipartRequest('POST', Uri.parse('https://server-3ath.onrender.com/get_tags'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = jsonDecode(await response.stream.bytesToString());
      List<String> keywords = List<String>.from(responseData['keywords']);
      setState(() {
        skills = keywords;
        isProcessing = false;
      });
    } else {
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing file')),
      );
    }
  }

  Future<void> storeResumeAndTagsInFirestore(File file, List<String> tags) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      String base64File = base64Encode(await file.readAsBytes());
      await FirebaseFirestore.instance.collection('user_tags').doc(userId).set({
        'tags': tags,
        'resume': base64File,
        'isPrivate': isPrivate,
        'timestamp': FieldValue.serverTimestamp(),
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
    }
  }

  void onChipSelected(String skill) {
    setState(() {
      if (selectedSkills.contains(skill)) {
        selectedSkills.remove(skill);
      } else if (selectedSkills.length < 10) {
        selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("RESUMO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown, letterSpacing: 2)),
                const SizedBox(height: 20),
                const Text("UPLOAD YOUR RESUME", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("SO THAT WE CAN START PROCESSING", style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.attach_file, color: Colors.black),
                  label: Text(selectedFileName ?? "Choose file..", style: const TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], minimumSize: const Size(250, 40)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selectedFile != null ? () => uploadFile(selectedFile!) : null,
                  child: isProcessing ? const CircularProgressIndicator() : const Text("Submit"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(250, 40)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((skill) {
                    bool isSelected = selectedSkills.contains(skill);
                    return ChoiceChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (bool selected) => onChipSelected(skill),
                      selectedColor: Colors.orange,
                      backgroundColor: Colors.grey[300],
                    );
                  }).toList(),
                ),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text("Select any ten skills that best describe you", style: TextStyle(color: Colors.red, fontSize: 14)),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: isPrivate,
                      onChanged: (bool? value) => setState(() => isPrivate = value ?? false),
                    ),
                    const Text("Keep your Resume private"),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, minimumSize: const Size(120, 40)),
                      child: const Text("Back", style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: selectedSkills.length == 10
                          ? () async {
                        await storeResumeAndTagsInFirestore(selectedFile!, selectedSkills);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditDetailsPage()),
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        minimumSize: const Size(120, 40),
                      ),
                      child: const Text("Proceed", style: TextStyle(color: Colors.white)),
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
}
