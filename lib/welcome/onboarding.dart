import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demos/welcome/signin.dart';
import 'package:demos/welcome/signup.dart';
// import 'package:demos/PlantDetectorScreen.dart';
import 'package:demos/main_screen.dart';

final supabase = Supabase.instance.client;

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  // Function for smooth transition effect
  void _navigateWithTransition(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500), // Adjust speed
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation, // Fade animation effect
            child: child,
          );
        },
      ),
    );
  }

  // Google Sign-In Function
 Future<AuthResponse> signInWithGoogle() async {
    /// Web Client ID from Google Cloud Console
    const webClientId = '1045039675145-odfdmmoevqejh7n0pmo4ohus2n0avltr.apps.googleusercontent.com';

    // Create GoogleSignIn instance
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId, // Important: your web client ID
    );

    try {
      // Trigger the sign-in flow
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google sign-in canceled';
      }

      // Get authentication tokens
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'No ID Token found';
      }

      // Sign in with Supabase using the Google tokens
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        print("✅ Successfully signed in: \${response.user!.email}");

        // Navigate to Plant Detector Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Google'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return response;
    } catch (error) {
      print('❌ Error signing in with Google: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sign in failed: $error'),
            backgroundColor: Colors.red),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 100.0),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/plant1.jpeg"), // Background image
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 30.0),
              child: Text(
                "The best\nApp for\nYour plants",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 53.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 215),

            // Sign In Button
            GestureDetector(
              onTap: () {
                _navigateWithTransition(context, SignIN());
              },
              child: Container(
                padding: EdgeInsets.only(top: 8.5, bottom: 8.5),
                margin: EdgeInsets.only(left: 31.0, right: 31.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff4caf50),
                      Color(0xff2e7d32),
                      Color(0xff1b5e20),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    "Sign in",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 17),

            // Create Account Button
            GestureDetector(
              onTap: () {
                _navigateWithTransition(context, SignUp());
              },
              child: Container(
                padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                margin: EdgeInsets.only(left: 30.0, right: 30.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.transparent, // No background color
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    "Create an Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height / 25),

            Text(
              "Or continue with",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
            SizedBox(height: 8.0),

            // Google Sign-In Button
            InkWell(
              onTap: () async {
                try {
                  await signInWithGoogle();
                } catch (e) {
                  // Error already handled in the function
                }
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Image.asset(
                  "assets/Google.png",
                  height: 35,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
