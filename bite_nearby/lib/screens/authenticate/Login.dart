import 'package:bite_nearby/services/auth.dart';
import 'package:bite_nearby/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:bite_nearby/Coolors.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({super.key, required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';
  String password = '';
  String error = '';

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Coolors.ritaBlack),
      prefixIcon: Icon(icon, color: Coolors.wineRed),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Coolors.wineRed),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Coolors.wineRed),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Coolors.wineRed, width: 2.0),
      ),
      filled: true,
      fillColor: Coolors.ivoryCream,
      focusColor: Coolors.wineRed.withOpacity(0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Loading()
        : Scaffold(
            backgroundColor: Coolors.lightOrange,
            appBar: null, // Remove default app bar
            body: Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Coolors.charcoalBlack,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bite Nearby',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Coolors.lightOrange,
                          letterSpacing: 1.5,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.person, color: Coolors.lightOrange),
                        label: Text(
                          'Register',
                          style: TextStyle(color: Coolors.lightOrange),
                        ),
                        onPressed: () {
                          widget.toggleView();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 40.0),
                        child: Card(
                          color: Coolors.ivoryCream,
                          elevation: 8.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.bold,
                                      color: Coolors.ritaBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 40.0),
                                  TextFormField(
                                    decoration: _buildInputDecoration(
                                        'Email', Icons.email),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                            ? 'Enter an email'
                                            : null,
                                    onChanged: (val) {
                                      setState(() => email = val);
                                    },
                                  ),
                                  const SizedBox(height: 40.0),
                                  TextFormField(
                                    decoration: _buildInputDecoration(
                                        'Password', Icons.lock),
                                    validator: (val) => val != null &&
                                            val.length < 6
                                        ? 'Enter a password 6+ characters long'
                                        : null,
                                    obscureText: true,
                                    onChanged: (val) {
                                      setState(() => password = val);
                                    },
                                  ),
                                  const SizedBox(height: 30.0),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15.0, horizontal: 30.0),
                                      backgroundColor: Coolors.charcoalBlack,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        setState(() => loading = true);
                                        dynamic result = await _auth
                                            .SignInWithEmailAndPassword(
                                                email, password);
                                        if (result == null) {
                                          setState(() {
                                            error =
                                                'Username or password are not correct';
                                            loading = false;
                                          });
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Log In',
                                      style: TextStyle(
                                          fontSize: 16.0,
                                          color: Coolors.lightOrange),
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  if (error.isNotEmpty)
                                    Text(
                                      error,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 14.0),
                                    ),
                                  const SizedBox(height: 20.0),
                                  TextButton(
                                    onPressed: () {
                                      // Add forgot password functionality
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Coolors.wineRed,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}
