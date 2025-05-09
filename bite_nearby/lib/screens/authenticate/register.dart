import 'package:flutter/material.dart';
import 'package:bite_nearby/screens/authenticate/additionalInfoPage.dart';
import 'package:bite_nearby/services/auth.dart';
import 'package:intl/intl.dart';
import 'package:bite_nearby/Coolors.dart';

class Register extends StatefulWidget {
  final Function toggleView;
  const Register({super.key, required this.toggleView});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String username = '';
  DateTime? dateOfBirth;
  String gender = 'Female';
  String error = '';

  void navigateToAdditionalInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdditionalInfoPage(username: username),
      ),
    );
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Coolors.wineRed,
              onPrimary: Coolors.lightOrange,
              onSurface: Coolors.ritaBlack,
            ),
            dialogBackgroundColor: Coolors.ivoryCream,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != dateOfBirth) {
      setState(() {
        dateOfBirth = picked;
      });
    }
  }

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
      focusColor: Coolors.charcoalBlack.withOpacity(0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coolors.lightOrange,
      appBar: null, // Remove default app bar
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Coolors.charcoalBlack,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                    'Log In',
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
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Create an Account',
                              style: TextStyle(
                                fontSize: 24.0,
                                fontWeight: FontWeight.bold,
                                color: Coolors.ritaBlack,
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              decoration: _buildInputDecoration(
                                  'Username', Icons.person),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter a username'
                                  : null,
                              onChanged: (val) {
                                setState(() => username = val);
                              },
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              decoration:
                                  _buildInputDecoration('Email', Icons.email),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Enter an email'
                                  : null,
                              onChanged: (val) {
                                setState(() => email = val);
                              },
                            ),
                            const SizedBox(height: 20.0),
                            TextFormField(
                              decoration:
                                  _buildInputDecoration('Password', Icons.lock),
                              validator: (val) => val != null && val.length < 6
                                  ? 'Enter a password 6+ characters long'
                                  : null,
                              obscureText: true,
                              onChanged: (val) {
                                setState(() => password = val);
                              },
                            ),
                            const SizedBox(height: 20.0),
                            GestureDetector(
                              onTap: () => selectDateOfBirth(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 10.0),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Coolors.charcoalBlack,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Coolors.ivoryCream,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateOfBirth == null
                                          ? 'Select Date of Birth'
                                          : DateFormat('yyyy-MM-dd')
                                              .format(dateOfBirth!),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: dateOfBirth == null
                                            ? Colors.grey
                                            : Coolors.ritaBlack,
                                      ),
                                    ),
                                    Icon(Icons.calendar_today,
                                        color: Coolors.wineRed),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration(
                                  'Gender', Icons.person_outline),
                              dropdownColor: Coolors.ivoryCream,
                              style: TextStyle(color: Coolors.ritaBlack),
                              value: gender,
                              items: ['Male', 'Female']
                                  .map((gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() => gender = val ?? 'Male');
                              },
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Coolors.wineRed),
                            ),
                            const SizedBox(height: 30.0),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 30.0),
                                backgroundColor: Coolors.charcoalBlack,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  if (dateOfBirth == null) {
                                    setState(() {
                                      error =
                                          'Please select your date of birth';
                                    });
                                    return;
                                  }
                                  dynamic result =
                                      await _auth.registerWithEmailAndPassword(
                                          email, password);
                                  if (result != null) {
                                    navigateToAdditionalInfo(context);
                                  } else {
                                    setState(() =>
                                        error = 'Please supply a valid email');
                                  }
                                }
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                    fontSize: 16.0, color: Coolors.lightOrange),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            if (error.isNotEmpty)
                              Text(
                                error,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 14.0),
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
