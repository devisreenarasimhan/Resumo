import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Recruiters extends StatefulWidget {
  @override
  _RecruitersState createState() => _RecruitersState();
}

class _RecruitersState extends State<Recruiters> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _recruiters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecruiters();
  }

  Future<void> _fetchRecruiters() async {
    setState(() => _isLoading = true);
    try {
      // Get all recruiters
      final usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'Recruiter')
          .get();

      List<Map<String, dynamic>> recruiters = [];

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data();
        userData['id'] = doc.id;

        // Fetch recruiter's tags from RC_tags
        final recruiterTagsDoc = await _firestore
            .collection('RC_tags')
            .doc(doc.id)
            .get();

        List<String> tags = [];
        if (recruiterTagsDoc.exists && recruiterTagsDoc.data() != null) {
          tags = List<String>.from(recruiterTagsDoc.data()?['tags'] ?? []);
          print('Recruiter ${userData['email']} tags: $tags');
        }

        userData['tags'] = tags;
        recruiters.add(userData);
      }

      setState(() {
        _recruiters = recruiters;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching recruiters: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recruiters'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchRecruiters,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecruiters,
              child: ListView.builder(
                itemCount: _recruiters.length,
                padding: EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final recruiter = _recruiters[index];
                  final List<String> tags = List<String>.from(recruiter['tags'] ?? []);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recruiter Profile Info
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Icon(Icons.person, color: Colors.blue[900]),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recruiter['email'] ?? 'No email',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (recruiter['name'] != null)
                                      Text(
                                        recruiter['name'],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Skills/Tags Section
                          if (tags.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(
                              'Looking for skills in:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) => Chip(
                                label: Text(tag),
                                backgroundColor: Colors.blue[50],
                                labelStyle: TextStyle(
                                  color: Colors.blue[900],
                                ),
                              )).toList(),
                            ),
                          ],
                          if (tags.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'No skills specified',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
