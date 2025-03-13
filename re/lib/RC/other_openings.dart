import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class OtherOpenings extends StatefulWidget {
  @override
  _OtherOpeningsState createState() => _OtherOpeningsState();
}

class _OtherOpeningsState extends State<OtherOpenings> {
  List<Map<String, dynamic>> _openings = [];
  bool _isLoading = true;

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
          padding: EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            final opening = _openings[index];
            return _buildOpeningCard(opening);
          },
        ),
      ),
    );
  }

  Widget _buildOpeningCard(Map<String, dynamic> opening) {
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

    List<String> tags = [];
    if (opening['tags'] != null) {
      if (opening['tags'] is List) {
        tags = List<String>.from(opening['tags']);
      } else if (opening['tags'] is String) {
        tags = [opening['tags'] as String];
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.business, color: Colors.blue[900]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opening['title']?.toString() ?? 'No title',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(opening['companyName']?.toString() ?? 'No company name'),
                    ],
                  ),
                ),
              ],
            ),
            if (opening['description'] != null) ...[
              SizedBox(height: 8),
              Text(opening['description'].toString()),
            ],
            if (opening['location'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16),
                  SizedBox(width: 4),
                  Text(opening['location'].toString()),
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
            // Add count display with tap gesture
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
            SizedBox(height: 8),
            Text(
              opening['timestamp'] != null
                  ? DateTime.parse(opening['timestamp']).toString()
                  : 'No timestamp',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
