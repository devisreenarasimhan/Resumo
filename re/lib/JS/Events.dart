import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Events extends StatefulWidget {
  @override
  _EventsState createState() => _EventsState();
}

class _EventsState extends State<Events> {
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

      // Get user's name from users collection
      final userDoc = await _firestore
          .collection('users')
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

          }]),

        });
      } else {
        // Create new document
        await eventRef.set({
          'count': 1,
          'applied_users': [{
            'email': currentUser.email,
            'name': userName
          }],
          'event_title': event['title'],
          'event_description': event['description'],

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

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.event, color: Colors.blue[900], size: 20),
                  radius: 16,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event['title'] ?? 'No title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            // Description
            if (event['description'] != null) ...[
              SizedBox(height: 8),
              Text(
                event['description'].toString(),
                style: TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Location
            if (event['location'] != null && 
                event['location'].toString().isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event['location'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Tags
            if (event['tags'] != null && 
                (event['tags'] as List).isNotEmpty) ...[
              SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (event['tags'] as List).map((tag) => Padding(
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

            // Timestamp and Apply button
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event['timestamp'] != null
                        ? _formatTimestamp(DateTime.parse(event['timestamp']))
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

  // Add this helper method for better timestamp formatting
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
      body: SafeArea(
        child: _isLoading 
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshEvents,
                child: _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No events available',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: _events.length,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return _buildEventCard(event);
                        },
                      ),
              ),
      ),
    );
  }
}
