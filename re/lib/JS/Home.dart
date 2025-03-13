import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:re/JS/JSProfile.dart';
import 'package:re/LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Status.dart';
// Import the individual page files
import 'Openings.dart';
import 'Recruiters.dart';
import 'Upskills.dart';
import 'Trends.dart';
import 'Events.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;
  User? _firebaseUser;
  String? userId;
  String? _defaultHomePage;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    userId = _firebaseUser?.uid;
    _fetchUserName();
    
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
        if (account != null) {
          userId = account.id;
        }
      });
    });
    _googleSignIn.signInSilently();
    _loadDefaultHomePage();
  }

  Future<void> _fetchUserName() async {
    if (_firebaseUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_tags')
          .doc(_firebaseUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          var data = userDoc.data() as Map<String, dynamic>? ?? {};
          userName = data['name'] ?? 'Your Name';
        });
      }
    }
  }

  // Load the saved default home page from shared preferences
  Future<void> _loadDefaultHomePage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedHomePage = prefs.getString('user_default_homepage');
    if (savedHomePage == null) {
      // If no default home page is found, show the hover menu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHoverMenu(context);
      });
    }
    setState(() {
      _defaultHomePage = savedHomePage ?? 'Upskills'; // Default to 'Upskills' if none is set
    });
  }

  // Save the selected default home page
  Future<void> _saveDefaultHomePage(String page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user_default_homepage', page);
    setState(() {
      _defaultHomePage = page;
    });
  }

  // Show the hover menu to select the default home page
  void _showHoverMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("SET YOUR DEFAULT HOME PAGE"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(context, "Openings"),
              _buildMenuItem(context, "Recruiters"),
              _buildMenuItem(context, "Upskills"),
              _buildMenuItem(context, "Trends"),
              _buildMenuItem(context, "Events"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String title) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        _saveDefaultHomePage(title); // Save the selected home page
      },
    );
  }

  // Add this method back
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildHomeContent() {
    return _buildDefaultPage();
  }

  Widget _buildDefaultPage() {
    switch (_defaultHomePage) {
      case 'Recruiters':
        return Recruiters();
      case 'Upskills':
        return Upskills();
      case 'Trends':
        return Trends();
      case 'Events':
        return Events();
      case 'Openings':
      default:
        return Openings();
    }
  }

  // Add this method to fetch name from Firestore
  Future<String> _getNameFromFirestore() async {
    if (_firebaseUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('JS_Profile')
            .doc(_firebaseUser!.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return data['name'] ?? 'Your Name';
        }
      } catch (e) {
        print('Error fetching name: $e');
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => _showHoverMenu(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search),
          ),
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        child: Drawer(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.brown,
                        backgroundImage: _currentUser?.photoUrl != null ? NetworkImage(_currentUser!.photoUrl!) : null,
                        child: (_currentUser?.photoUrl == null && _firebaseUser?.photoURL == null)
                            ? Icon(Icons.person, size: 50)
                            : null,
                      ),
                      SizedBox(height: 10),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('JS_Profile')
                            .doc(_firebaseUser?.uid ?? '')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            return Text(
                              data['Name'] ?? 'Name',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                              ),
                            );
                          }
                          return Text(
                            '',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          );
                        },
                      ),
                      Text(
                        _currentUser != null
                            ? _currentUser!.email ?? 'Your email id'
                            : _firebaseUser != null
                            ? _firebaseUser!.email ?? 'Your email id'
                            : 'No Email',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.brown),
                        ),
                        onPressed: () {
                          if (userId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => JSProfile()),
                            );
                          }
                        },
                        child: Text("Manage your account", style: TextStyle(color: Colors.brown)),
                      ),
                    ],
                  ),
                ),
                Divider(),
                ExpansionTile(
                  leading: Icon(Icons.visibility, color: Colors.brown),
                  title: Text(
                    "Profile Views",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('profile_views')
                          .where('candidateEmail', isEqualTo: _firebaseUser?.email)
                          .orderBy('timestamp', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text('Something went wrong'),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No profile views yet',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final timestamp = (data['timestamp'] as Timestamp).toDate();
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[50],
                                  radius: 16,
                                  child: Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                title: Text(
                                  data['recruiterName'] ?? 'Unknown Recruiter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['recruiterEmail'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _formatTimeAgo(timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                ListTile(
                  leading: Icon(Icons.chat_bubble, color: Colors.brown),
                  title: Text("Inbox", style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.brown),
                  title: Text("Status", style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Status()),
                    );
                  },

                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.brown),
                  title: Text("About", style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () {},
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.brown),
                  title: Text("Log out", style: GoogleFonts.poppins(fontSize: 16)),
                  onTap: () async {
                    // Log out from Firebase
                    await FirebaseAuth.instance.signOut();

                    // Sign out from Google
                    GoogleSignIn googleSignIn = GoogleSignIn();
                    if (await googleSignIn.isSignedIn()) {
                      await googleSignIn.signOut();
                    }

                    setState(() {
                      _currentUser = null; // Clear user data
                      _firebaseUser = null; // Clear Firebase user data
                    });

                    // Navigate to login page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()), // Replace LoginPage() with your actual login page widget
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildHomeContent(), // Display the content dynamically based on the selected homepage
      ),
    );
  }
}
