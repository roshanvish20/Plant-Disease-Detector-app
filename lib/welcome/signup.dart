import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:demos/welcome/signin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool _isObscure = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
        },
        emailRedirectTo: null,
      );

      if (response.user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error creating account. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.user?.identities?.isEmpty ?? true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("An account with this email already exists."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Create profile with all required fields
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
          'avatar_url': null
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please check your email for verification link."),
              backgroundColor: Colors.green,
            ),
          );
          _navigateWithFadeTransition(context, SignIN());
        }
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = error.toString();
        debugPrint('Signup error: $errorMessage'); // Add this for debugging
        if (errorMessage.contains("User already registered")) {
          errorMessage = "An account with this email already exists.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
  void _navigateWithFadeTransition(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => page,
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
          Positioned.fill(
            child: Image.asset("assets/plant3.jpeg", fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 70.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Create your\nAccount",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      size: 30, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(21),
                    topRight: Radius.circular(21)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField("Enter Full Name", Icons.person_outline,
                            _nameController, 21),
                        _buildTextField(
                            "Email", Icons.email_outlined, _emailController, 38,
                            isEmail: true),
                        _buildPasswordField(),
                        const SizedBox(height: 27.0),
                        _buildSignUpButton(),
                        const SizedBox(height: 17.0),
                        _buildSignInText(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon,
      TextEditingController controller, int maxLength,
      {bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xff2e7d32),
                fontSize: 21.0,
                fontWeight: FontWeight.bold)),
        TextFormField(
          controller: controller,
          keyboardType:
              isEmail ? TextInputType.emailAddress : TextInputType.text,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "This field cannot be empty";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter $label",
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 13.0),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Password",
            style: TextStyle(
                color: Color(0xff2e7d32),
                fontSize: 21.0,
                fontWeight: FontWeight.bold)),
        TextFormField(
          controller: _passwordController,
          obscureText: _isObscure,
          inputFormatters: [LengthLimitingTextInputFormatter(21)],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Password cannot be empty";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: "Enter Your Password",
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _handleSignUp,
      child: Container(
        height: 51,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xff4caf50), Color(0xff2e7d32), Color(0xff1b5e20)],
              begin: Alignment.topLeft,
              end: Alignment.topRight),
          borderRadius: BorderRadius.circular(25),
        ),
        width: double.infinity,
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("SIGN UP",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21.0,
                      fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSignInText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ",
            style: TextStyle(fontSize: 16, color: Colors.black54)),
        GestureDetector(
          onTap: () {
            _navigateWithFadeTransition(context, SignIN());
          },
          child: const Text("Sign In",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green)),
        ),
      ],
    );
  }
}
