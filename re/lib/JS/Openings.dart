import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Openings extends StatefulWidget {
  @override
  _OpeningsState createState() => _OpeningsState();
}

class _OpeningsState extends State<Openings> {
  List<Map<String, dynamic>> _openings = [];
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchOpenings();
  }

  Future<void> _fetchOpenings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final snapshot = await FirebaseFirestore.instance.collection('RC_Profile').get();
      List<Map<String, dynamic>> allOpenings = [];

      for (var doc in snapshot.docs) {
        print('Fetching from doc: ${doc.id}'); // Debug print
        var data = doc.data();
        if (data.containsKey('openings')) {
          print('Found openings in doc: ${data['openings']}'); // Debug print
          var openings = data['openings'] as List<dynamic>;
          for (var opening in openings) {
            Map<String, dynamic> openingMap = Map<String, dynamic>.from(opening);
            if (openingMap['tags'] != null) {
              if (openingMap['tags'] is String) {
                openingMap['tags'] = [openingMap['tags']];
              } else if (openingMap['tags'] is List) {
                openingMap['tags'] = List<String>.from(openingMap['tags']);
              }
            } else {
              openingMap['tags'] = [];
            }
            allOpenings.add(openingMap);
          }
        }
      }

      print('Total openings found: ${allOpenings.length}'); // Debug print

      setState(() {
        _openings = allOpenings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching openings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyForOpening(Map<String, dynamic> opening) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to apply'))
        );
        return;
      }

      // Reference to opening_applied document
      final openingRef = _firestore.collection('opening_applied').doc(opening['id']);
      
      // Get current document
      final doc = await openingRef.get();
      
      if (doc.exists) {
        // Check if user already applied
        List<String> appliedUsers = List<String>.from(doc.data()?['applied_users'] ?? []);
        
        if (appliedUsers.contains(currentUser.email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have already applied for this opening'))
          );
          return;
        }

        // Update existing document
        await openingRef.update({
          'count': FieldValue.increment(1),
          'applied_users': FieldValue.arrayUnion([currentUser.email]),
          'last_applied': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        await openingRef.set({
          'count': 1,
          'applied_users': [currentUser.email],
          'opening_title': opening['title'],
          'company_name': opening['companyName'],
          'last_applied': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully applied for ${opening['title']}'),
          backgroundColor: Colors.green,
        )
      );
    } catch (e) {
      print('Error applying for opening: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply. Please try again.'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Openings'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchOpenings,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchOpenings,
        child: _openings.isEmpty
            ? ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            Center(child: Text('No openings available')),
          ],
        )
            : ListView.builder(
          itemCount: _openings.length,
          padding: EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, index) {
            final opening = _openings[index];
            return _buildOpeningCard(opening);
          },
        ),
      ),
    );
  }

  Widget _buildOpeningCard(Map<String, dynamic> opening) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.business, color: Colors.blue[900], size: 20),
                  radius: 16,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opening['title']?.toString() ?? 'No title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        opening['companyName']?.toString() ?? 'No company name',
                        style: TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (opening['description'] != null) ...[
              SizedBox(height: 8),
              Text(
                opening['description'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ],
            if (opening['location'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      opening['location'].toString(),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (opening['tags'] != null && opening['tags'].isNotEmpty) ...[
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (opening['tags'] as List).map((tag) => Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        tag.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[900]),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  )).toList(),
                ),
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    opening['timestamp'] != null
                        ? _formatTimestamp(DateTime.parse(opening['timestamp']))
                        : 'No date specified',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _applyForOpening(opening),
                  icon: Icon(Icons.check_circle_outline, size: 16),
                  label: Text('Apply', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
