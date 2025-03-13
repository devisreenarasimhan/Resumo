import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class Upskills extends StatefulWidget {
  @override
  _UpskillsState createState() => _UpskillsState();
}
class _UpskillsState extends State<Upskills> {
  List<String> _tags = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fetch data for all tags
  Future<void> _fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final tags = await fetchUserTags(userId);
      List<dynamic> allResults = [];

      // Loop through each tag and fetch search results
      for (var tag in tags) {
        final results = await fetchSearchResults(tag);
        allResults.addAll(results);  // Add results for each tag
      }

      setState(() {
        _tags = tags;
        _searchResults = allResults;
        _isLoading = false;
      });
    }
  }

  // Fetch tags from the user_tags collection
  Future<List<String>> fetchUserTags(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user_tags')
        .doc(userId)
        .get();

    if (snapshot.exists && snapshot.data() != null) {
      return List<String>.from(snapshot.data()?['tags'] ?? []);
    }
    return [];
  }

  // Fetch search results for a single tag
  Future<List<dynamic>> fetchSearchResults(String keyword) async {
    const apiKey = '33545b37c607ae90f898e486c3310e07539550c30671735295389f743688c8bb'; // Replace with your actual API key
    final url = 'https://serpapi.com/search.json?q=$keyword Learn Study Upskill&api_key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['organic_results'] ?? [];
    } else {
      throw Exception('Failed to load search results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'UPSKILLS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search here...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          // Display searched tags
          if (_tags.isNotEmpty)
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return SearchResultCard(
                    result: result,
                    tags: _tags, // Pass tags to the card
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class SearchResultCard extends StatelessWidget {
  final dynamic result;
  final List<String> tags;  // Pass tags to the card

  SearchResultCard({required this.result, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  result['thumbnail'] ?? 'https://www.seotoolstack.com/placeholder/600x300/d5d5d5/584959/Technology/webp',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 25,
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['title'] ?? 'Course Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  result['snippet'] ?? 'Description of course comes here.',
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tags.isNotEmpty ? tags[Random().nextInt(tags.length)] : 'No tags available',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.brown),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
