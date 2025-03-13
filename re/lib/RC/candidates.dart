import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class Candidates extends StatefulWidget {
  @override
  _CandidatesState createState() => _CandidatesState();
}

class _CandidatesState extends State<Candidates> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _jobSeekers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndSortCandidates();
  }

  Future<void> _fetchAndSortCandidates() async {
    setState(() => _isLoading = true);
    try {
      // Get recruiter's tags
      String recruiterId = _auth.currentUser?.uid ?? '';
      final recruiterTagsDoc = await _firestore
          .collection('RC_tags')
          .doc(recruiterId)
          .get();

      // Convert recruiter tags to lowercase
      List<String> recruiterTags = [];
      if (recruiterTagsDoc.exists && recruiterTagsDoc.data() != null) {
        recruiterTags = List<String>.from(recruiterTagsDoc.data()?['tags'] ?? [])
            .map((tag) => tag.toLowerCase())
            .toList();
        print('Recruiter tags (lowercase): $recruiterTags');
      }

      // Get all Job Seekers
      final usersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'Job Seeker')
          .get();

      List<Map<String, dynamic>> jobSeekers = [];

      for (var doc in usersSnapshot.docs) {
        Map<String, dynamic> userData = doc.data();
        userData['id'] = doc.id;

        // Get job seeker's tags from user_Tags collection
        final userTagsDoc = await _firestore
            .collection('user_tags')
            .doc(doc.id)
            .get();

        List<String> originalTags = [];
        if (userTagsDoc.exists && userTagsDoc.data() != null) {
          originalTags = List<String>.from(userTagsDoc.data()?['tags'] ?? []);
          print('Job Seeker ${userData['email']} original tags from user_Tags: $originalTags');
        }

        // Store original tags for display
        userData['tags'] = originalTags;

        // Calculate matches using lowercase comparison
        int matchScore = 0;
        Set<String> matchedTags = {};

        for (String jsTag in originalTags) {
          String lowerJsTag = jsTag.toLowerCase();
          if (recruiterTags.contains(lowerJsTag)) {
            matchScore++;
            matchedTags.add(jsTag); // Store original tag for highlighting
            print('Match found: $jsTag');
          }
        }

        // Calculate percentage
        int matchPercentage = recruiterTags.isEmpty ?
            0 : ((matchScore / recruiterTags.length) * 100).round();

        userData['matchScore'] = matchScore;
        userData['matchPercentage'] = matchPercentage;
        userData['matchedTags'] = matchedTags.toList();

        print('Match for ${userData['email']}: Score=$matchScore, Percentage=$matchPercentage%');
        jobSeekers.add(userData);
      }

      // Sort by match percentage
      jobSeekers.sort((a, b) =>
        (b['matchPercentage'] as int).compareTo(a['matchPercentage'] as int));

      setState(() {
        _jobSeekers = jobSeekers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching candidates: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendViewNotification(String candidateEmail) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot recruiterDoc = await _firestore
          .collection('RC_Profile')
          .doc(currentUser.uid)
          .get();

      String recruiterName = recruiterDoc.get('name') ?? 'A Recruiter';
      String recruiterEmail = currentUser.email ?? 'No email available';

      // Store view history in Firestore
      await _firestore.collection('profile_views').add({
        'candidateEmail': candidateEmail,
        'recruiterEmail': recruiterEmail,
        'recruiterName': recruiterName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile view recorded'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error recording view: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record view'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Candidates'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchAndSortCandidates,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAndSortCandidates,
              child: ListView.builder(
                itemCount: _jobSeekers.length,
                padding: EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final jobSeeker = _jobSeekers[index];
                  final List<String> tags = List<String>.from(jobSeeker['tags'] ?? []);
                  final int matchScore = jobSeeker['matchScore'] ?? 0;
                  final int matchPercentage = jobSeeker['matchPercentage'] ?? 0;
                  final List<String> matchedTags = List<String>.from(jobSeeker['matchedTags'] ?? []);

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: InkWell(
                      onTap: () => _sendViewNotification(jobSeeker['email']),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email and Match Score
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getMatchColor(matchPercentage),
                                  child: Text(
                                    '$matchPercentage%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jobSeeker['email'] ?? 'No email',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Match: $matchPercentage% ($matchScore matched skills)',
                                        style: TextStyle(
                                          color: _getMatchColor(matchPercentage),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Skills Section
                            SizedBox(height: 16),
                            Text(
                              'Skills:',
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
                              children: tags.map((tag) {
                                bool isMatched = matchedTags
                                    .map((t) => t.toLowerCase())
                                    .contains(tag.toLowerCase());
                                return Chip(
                                  label: Text(tag),
                                  backgroundColor: isMatched ? Colors.green[50] : Colors.grey[200],
                                  labelStyle: TextStyle(
                                    color: isMatched ? Colors.green[900] : Colors.black87,
                                    fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                                  ),
                                );
                              }).toList(),
                            ),
                            if (tags.isEmpty)
                              Text(
                                'No skills listed',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
