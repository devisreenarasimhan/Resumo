import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Status extends StatefulWidget {
  @override
  _StatusState createState() => _StatusState();
}

class _StatusState extends State<Status> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<String> _statusTypes = [
    'Applied',
    'Selected',
    'Rejected',
    'Shortlisted',
    'Waiting'
  ];

  @override
  void initState() {
    super.initState();
    _markNotificationsAsRead();
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final unreadStatuses = await _firestore
          .collection('JC_Status')
          .where('candidateEmail', isEqualTo: currentUser.email)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadStatuses.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchApplicationsByStatus(String status) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      if (status == 'Applied') {
        // Query to find documents where the user is in applied_users
        final statusQuery = await _firestore
            .collection('opening_applied')
            .where('applied_users', arrayContains: currentUser.email)
            .get();

        List<Map<String, dynamic>> applications = [];

        for (var doc in statusQuery.docs) {
          Map<String, dynamic> data = doc.data();

          // Extract the required details from the document
          data['companyName'] = data['company_name'] ?? 'Unknown Company';
          data['count'] = data['count'] ?? 0;
          data['lastApplied'] = data['last_applied']?.toDate().toString() ?? 'Unknown';
          data['openingTitle'] = data['opening_title'] ?? 'Unknown Position';

          applications.add(data);
        }

        return applications;
      }

      // You can handle other statuses like 'Selected', 'Rejected', etc. here.

      return [];
    } catch (e) {
      print('Error fetching applications: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Application Status'),
      ),
      body: Column(
        children: [
          // Horizontal Status Bar with SingleChildScrollView for scrolling
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_statusTypes.length, (index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          width: 4,
                          color: _selectedIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                        ),
                      ),
                      color: _selectedIndex == index ? Colors.white : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(_statusTypes[index]),
                          color: _getStatusColor(_statusTypes[index]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _statusTypes[index],
                          style: TextStyle(
                            color: _selectedIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            fontWeight: _selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content Area
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchApplicationsByStatus(_statusTypes[_selectedIndex]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStatusIcon(_statusTypes[_selectedIndex]),
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No ${_statusTypes[_selectedIndex].toLowerCase()} applications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final application = snapshot.data![index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          application['openingTitle'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(application['companyName']),
                            SizedBox(height: 4),
                            Text(
                              'Applications: ${application['count']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Last Applied: ${application['lastApplied']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(_statusTypes[_selectedIndex]).withOpacity(0.2),
                          child: Icon(
                            _getStatusIcon(_statusTypes[_selectedIndex]),
                            color: _getStatusColor(_statusTypes[_selectedIndex]),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Applied':
        return Icons.send;
      case 'Selected':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      case 'Shortlisted':
        return Icons.access_time;
      case 'Waiting':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.blue;
      case 'Selected':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Shortlisted':
        return Colors.orange;
      case 'Waiting':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
