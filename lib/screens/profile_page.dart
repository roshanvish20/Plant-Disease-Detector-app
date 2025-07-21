import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Add this import for ImageFilter

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  // Fix: Initialize animation controller and animation in initState, not as late variables
  AnimationController? _animationController;
  Animation<double>? _animation;

  String? _profileImageUrl;
  String _userName = 'Fetching...';
  String _email = 'Fetching...';
  bool _isEmailVisible = false;
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Initialize animation controller in initState
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    _animationController!.forward();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  /// Fetches user profile data from Supabase
  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoading = true);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No user found');
        return;
      }

      // Fetch profile data from Supabase
      final response = await _supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _userName = response['full_name'] ?? 'No Name';
          _profileImageUrl = response['avatar_url'];
          _email = user.email ?? 'No Email';
        });
      } else {
        debugPrint('Profile not found, creating a new one...');

        final defaultAvatar = 'https://via.placeholder.com/150';

        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': user.userMetadata?['name'] ?? 'New User',
          'email': user.email,
          'avatar_url': defaultAvatar,
        });

        setState(() {
          _userName = user.userMetadata?['name'] ?? 'New User';
          _email = user.email ?? 'No Email';
          _profileImageUrl = defaultAvatar;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _showSnackBar('Error loading profile', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Handles user logout
  Future<void> _signOut() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;

      setState(() => _isLoading = true);
      await _supabase.auth.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      _showSnackBar('Error signing out', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.tealAccent.shade400 : Colors.lightBlue.shade700;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // ImageFilter is now available
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [const Color(0xFF1A237E), const Color(0xFF121212)]
                      : [Colors.lightBlue.shade100, Colors.white],
                ),
              ),
              // Fix: Safely check if _animation is initialized
              child: _animation != null
                  ? FadeTransition(
                      opacity: _animation!,
                      child: _buildProfileContent(primaryColor, isDarkMode, cardColor),
                    )
                  : _buildProfileContent(primaryColor, isDarkMode, cardColor),
            ),
    );
  }

  // Extracted profile content into a separate method for better readability
  Widget _buildProfileContent(Color primaryColor, bool isDarkMode, Color cardColor) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Image (Non-editable)
            Hero(
              tag: 'profileImage',
              child: CircleAvatar(
                radius: 75,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(
                        "$_profileImageUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}")
                    : null,
                child: _profileImageUrl == null
                    ? Icon(Icons.person, size: 75, color: isDarkMode ? Colors.white70 : Colors.black54)
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            
            // User Name Section (Non-editable)
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Email visibility toggle with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _isEmailVisible = !_isEmailVisible);
                    HapticFeedback.lightImpact();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            AnimatedRotation(
                              turns: _isEmailVisible ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            height: _isEmailVisible ? null : 0,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: _isEmailVisible ? 10 : 0,
                              ),
                              child: Opacity(
                                opacity: _isEmailVisible ? 1.0 : 0.0,
                                child: Text(
                                  _email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Sign Out Button with gradient effect
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
                shadowColor: Colors.redAccent.withOpacity(0.5),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
              ).copyWith(
                backgroundColor: MaterialStateProperty.all(
                  isDarkMode ? Colors.redAccent.shade700 : Colors.redAccent,
                ),
              ),
              onPressed: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}