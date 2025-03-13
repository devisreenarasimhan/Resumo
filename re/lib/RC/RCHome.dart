import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:re/LoginPage.dart';
import 'package:re/RC/ProfileRC.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the individual page files
import 'candidates.dart';
import 'RCtrends.dart';
import 'other_events.dart';
import 'other_openings.dart';

class RCHome extends StatefulWidget {
  @override
  _RCHomeState createState() => _RCHomeState();
}

class _RCHomeState extends State<RCHome> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;
  String? _defaultHomePage;
  User? _firebaseUser;
  String userName = 'Your Name';

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
    _firebaseUser = FirebaseAuth.instance.currentUser;
    _loadDefaultHomePage();
    _fetchUserName();
  }

  Future<void> _loadDefaultHomePage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedHomePage = prefs.getString('user_default_homepage');
    if (savedHomePage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHoverMenu(context);
      });
    }
    setState(() {
      _defaultHomePage = savedHomePage ?? 'Candidates';
    });
  }

  Future<void> _saveDefaultHomePage(String page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user_default_homepage', page);
    setState(() {
      _defaultHomePage = page;
    });
  }

  Future<void> _fetchUserName() async {
    if (_firebaseUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('RC_Profile')
            .doc(_firebaseUser!.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            userName = doc.data()?['name'] ?? 'Your Name';
          });
        }
      } catch (e) {
        print('Error fetching user name: $e');
      }
    }
  }

  void _showHoverMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("SET YOUR DEFAULT HOME PAGE"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(context, "Candidates"),
              _buildMenuItem(context, "RC Trends"),
              _buildMenuItem(context, "Other Openings"),
              _buildMenuItem(context, "Other Events"),
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
        _saveDefaultHomePage(title);
      },
    );
  }

  Widget _buildHomeContent() {
    print("Default Home Page: $_defaultHomePage"); // Debugging line
    switch (_defaultHomePage) {
      case 'RC Trends':
        return RCtrends();
      case 'Other Openings':
        return OtherOpenings();
      case 'Other Events':
        return OtherEvents();
      case 'Candidates':
      default:
        return Candidates();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("H O M E"),
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
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.brown,
                      backgroundImage: _currentUser?.photoUrl != null
                          ? NetworkImage(_currentUser!.photoUrl!)
                          : _firebaseUser?.photoURL != null
                              ? NetworkImage(_firebaseUser!.photoURL!)
                              : null,
                      child: (_currentUser?.photoUrl == null && _firebaseUser?.photoURL == null)
                          ? Icon(Icons.person, color: Colors.white, size: 50)
                          : null,
                    ),
                    SizedBox(height: 10),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('RC_Profile')
                          .doc(_firebaseUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data?.data() != null) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          return Text(
                            data['name'] ?? 'Your Name',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          );
                        }
                        return Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                          ),
                        );
                      },
                    ),
                    Text(
                      _currentUser?.email ?? _firebaseUser?.email ?? 'No Email',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey
                      ),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.brown),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProfileRC()),
                        );
                      },
                      child: Text("Manage your account", style: TextStyle(color: Colors.brown)),
                    ),
                  ],
                ),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.chat_bubble, color: Colors.brown),
                title: Text("Inbox", style: GoogleFonts.poppins(fontSize: 16)),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.star, color: Colors.brown),
                title: Text("Status", style: GoogleFonts.poppins(fontSize: 16)),
                onTap: () {},
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildHomeContent(),
      ),
    );
  }
}
