import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bite_nearby/Coolors.dart';

class AdditionalInfoPage extends StatefulWidget {
  final String username;

  const AdditionalInfoPage({super.key, required this.username});
  @override
  _AdditionalInfoPageState createState() => _AdditionalInfoPageState();
}

class _AdditionalInfoPageState extends State<AdditionalInfoPage> {
  int currentPage = 0;

  List<String> commonAllergens = [
    'Peanuts',
    'Tree nuts',
    'Dairy ',
    'Eggs',
    'Fish',
    'Shellfish',
    'Wheat',
    'Soy'
  ];
  List<String> preferredIngredients = [
    'Chicken',
    'Beef',
    'Vegetables',
    'Fruits',
    'Cheese',
    'Rice',
    'Pasta'
  ];

  List<String> selectedAllergens = [];
  List<String> selectedPreferred = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coolors.lightOrange,
      appBar: null, // Remove default app bar
      body: Column(
        children: [
          // Custom header matching Register/SignIn pages
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
                  'Additional Information',
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Coolors.lightOrange,
                    letterSpacing: 1.5,
                  ),
                ),
                // Empty container to maintain spacing symmetry
                Container(width: 80),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        switch (currentPage) {
                          case 0:
                            return _buildSelectionPage(
                              title: 'Select Your Allergens',
                              options: commonAllergens,
                              selectedItems: selectedAllergens,
                            );
                          case 1:
                            return _buildSelectionPage(
                              title: 'Select Preferred Ingredients',
                              options: preferredIngredients,
                              selectedItems: selectedPreferred,
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPage({
    required String title,
    required List<String> options,
    required List<String> selectedItems,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        Expanded(
          child: Card(
            color: Coolors.ivoryCream,
            elevation: 4,
            child: ListView(
              children: options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: selectedItems.contains(option),
                  activeColor: Coolors.wineRed,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedItems.add(option);
                      } else {
                        selectedItems.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (currentPage > 0)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentPage -= 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Coolors.charcoalBlack,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Coolors.lightOrange,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              if (currentPage < 1) {
                setState(() {
                  currentPage += 1;
                });
              } else {
                _submitSelections();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Coolors.charcoalBlack,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              currentPage < 1 ? 'Next' : 'Submit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Coolors.lightOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitSelections() async {
    try {
      // Get the current user's UID
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Save data to Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.uid)
          .set({
        'allergens': selectedAllergens,
        'preferredIngredients': selectedPreferred,
        'username': widget.username,
        'id': currentUser.uid,
      }, SetOptions(merge: true)); // Merge data with existing user document

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved successfully!')),
      );

      // Navigate back or to the main app screen
      Navigator.pop(context);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving preferences: $e')),
      );
    }
  }
}
