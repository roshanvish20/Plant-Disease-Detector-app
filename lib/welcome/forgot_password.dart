import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:demos/welcome/signin.dart'; // Import the SignIn page (login page)

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form key for validation

  // Function to show Success Dialog and navigate to Login page
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text("A password reset link has been sent to your email."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _navigateToSignIn();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Function to handle the forgot password process
  void _handleForgotPassword() {
    if (_formKey.currentState!.validate()) {
      // If form is valid, proceed to send reset link
      _showSuccessDialog();
    }
  }

  // Email validation function
  String? _validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return "Email cannot be empty";
    }
    if (email.length > 40) {
      return "Email must be less than 40 characters";
    }
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);
    if (!regex.hasMatch(email)) {
      return "Enter a valid email address";
    }
    return null; // Valid email
  }

  // Navigate to SignIn with Fade Transition
  void _navigateToSignIn() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => SignIN(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/plant1.jpeg", // Change to your actual background image path
              fit: BoxFit.cover,
            ),
          ),
          // White Container with UI
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey, // Assign form key
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff485935),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Enter your email to receive a password reset link.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    SizedBox(height: 20),

                    // Email input field with validation
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Enter Your Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      validator: _validateEmail, // Apply email validation
                      inputFormatters: [
                        // Restrict input to valid characters for email
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._%+-]')),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Submit button for Forgot Password
                    ElevatedButton(
                      onPressed: _handleForgotPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff4caf50),
                        padding: EdgeInsets.symmetric(vertical: 13.0, horizontal: 50.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        "Send Reset Link",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 17),

                    // Back to Login Button with Fade Transition
                    TextButton(
                      onPressed: _navigateToSignIn,
                      child: Text(
                        "Back to Login",
                        style: TextStyle(fontSize: 14, color: Color(0xff485935)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
