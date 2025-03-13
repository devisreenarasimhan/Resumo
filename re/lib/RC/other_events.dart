import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class OtherEvents extends StatefulWidget {
  @override
  _OtherEventsState createState() => _OtherEventsState();
}

class _OtherEventsState extends State<OtherEvents> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final snapshot = await FirebaseFirestore.instance.collection('RC_Profile').get();
      List<Map<String, dynamic>> allEvents = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        if (data.containsKey('events')) {
          var events = data['events'] as List<dynamic>;
          for (var event in events) {
            // Convert event to Map<String, dynamic> and ensure tags is a List
            Map<String, dynamic> eventMap = Map<String, dynamic>.from(event);
            if (eventMap['tags'] != null) {
              if (eventMap['tags'] is String) {
                eventMap['tags'] = [eventMap['tags']];
              } else if (eventMap['tags'] is List) {
                eventMap['tags'] = List<String>.from(eventMap['tags']);
              }
            } else {
              eventMap['tags'] = [];
            }
            allEvents.add(eventMap);
          }
        }
      }

      setState(() {
        _events = allEvents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add refresh functionality
  Future<void> _refreshEvents() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchEvents();
  }

  Future<void> _applyForEvent(Map<String, dynamic> event) async {
    try {
      // Get current user
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to apply for this event'))
        );
        return;
      }

      // Get user's name from user_tags collection
      final userDoc = await _firestore
          .collection('user_tags')
          .doc(currentUser.uid)
          .get();
      
      String userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Reference to events_applied document
      final eventRef = _firestore
          .collection('events_applied')
          .doc(event['id'] ?? DateTime.now().toIso8601String());
      
      // Get current document
      final doc = await eventRef.get();
      
      if (doc.exists) {
        // Check if user already applied
        List<Map<String, dynamic>> appliedUsers = 
            List<Map<String, dynamic>>.from(doc.data()?['applied_users'] ?? []);
        
        if (appliedUsers.any((user) => user['email'] == currentUser.email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You have already applied for this event'))
          );
          return;
        }

        // Update existing document
        await eventRef.update({
          'count': FieldValue.increment(1),
          'applied_users': FieldValue.arrayUnion([{
            'email': currentUser.email,
            'name': userName,
            'timestamp': FieldValue.serverTimestamp(),
          }]),
          'last_applied': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        await eventRef.set({
          'count': 1,
          'applied_users': [{
            'email': currentUser.email,
            'name': userName,
            'timestamp': FieldValue.serverTimestamp(),
          }],
          'event_title': event['title'],
          'event_description': event['description'],
          'last_applied': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully applied for ${event['title']}'),
          backgroundColor: Colors.green,
        )
      );
    } catch (e) {
      print('Error applying for event: $e');
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
        title: Text('Events'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshEvents,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshEvents,
        child: _events.isEmpty
            ? ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            Center(child: Text('No events available')),
          ],
        )
            : ListView.builder(
          itemCount: _events.length,
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            final event = _events[index];
            print('Building event card: ${event['title']}'); // Debug print
            return _buildEventCard(event);
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final random = Random();
    final count = random.nextInt(10) + 1;
    
    // Generate random users list
    List<Map<String, String>> generateRandomUsers(int count) {
      return List.generate(count, (index) {
        int userNumber = random.nextInt(1000);
        return {
          'username': 'user$userNumber',
          'email': 'user$userNumber@gmail.com'
        };
      });
    }

    // Safely convert tags to List<String>
    List<String> tags = [];
    if (event['tags'] != null) {
      if (event['tags'] is List) {
        tags = List<String>.from(event['tags']);
      } else if (event['tags'] is String) {
        tags = [event['tags'] as String];
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['title'] ?? '',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(event['description'] ?? ''),
            if (event['location'] != null && event['location'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16),
                  SizedBox(width: 4),
                  Text(event['location'].toString()),
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
            SizedBox(height: 8),
            // Modified count display with tap gesture
            GestureDetector(
              onTap: () {
                final users = generateRandomUsers(count);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Registered Users'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: users.map((user) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['username']!,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(user['email']!),
                              Divider(),
                            ],
                          ),
                        )).toList(),
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
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Count: $count',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event['timestamp'] != null
                      ? _formatTimestamp(DateTime.parse(event['timestamp']))
                      : 'No timestamp',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _applyForEvent(event),
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
