import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bite_nearby/Coolors.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  _PreferencesPageState createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  List<String> commonAllergens = [
    'Peanuts',
    'Tree nuts',
    'Dairy',
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
  bool isLoading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            selectedAllergens =
                List<String>.from(snapshot.get('allergens') ?? []);
            selectedPreferred =
                List<String>.from(snapshot.get('preferredIngredients') ?? []);
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching preferences: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildHeader() {
    return Container(
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
            'Safe & Preferred',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Coolors.lightOrange,
              letterSpacing: 1.5,
            ),
          ),
          if (!isLoading)
            IconButton(
              icon: Icon(
                isEditing ? Icons.save : Icons.edit,
                color: Coolors.lightOrange,
                size: 28,
              ),
              onPressed: () {
                if (isEditing) {
                  _savePreferences();
                }
                setState(() {
                  isEditing = !isEditing;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Coolors.charcoalBlack,
          fontFamily: 'Times New Roman',
        ),
      ),
    );
  }

  Widget _buildItemList(List<String> items, String emptyMessage) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          emptyMessage,
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: items.map((item) {
        return Chip(
          label: Text(
            item,
            style: TextStyle(
              color: Coolors.charcoalBlack,
            ),
          ),
          backgroundColor: Coolors.lightOrange.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditableItemList(
      List<String> allItems, List<String> selectedItems) {
    return Column(
      children: allItems.map((item) {
        return CheckboxListTile(
          title: Text(
            item,
            style: TextStyle(
              color: Coolors.charcoalBlack,
              fontSize: 16,
            ),
          ),
          value: selectedItems.contains(item),
          activeColor: Coolors.wineRed,
          checkColor: Colors.white,
          onChanged: isEditing
              ? (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedItems.add(item);
                    } else {
                      selectedItems.remove(item);
                    }
                  });
                }
              : null,
        );
      }).toList(),
    );
  }

  Future<void> _savePreferences() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'allergens': selectedAllergens,
        'preferredIngredients': selectedPreferred,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preferences updated successfully!'),
          backgroundColor: Coolors.wineRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating preferences: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Coolors.ivoryCream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                    color: Coolors.wineRed,
                  ))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    '               Your Allergens       '),
                                isEditing
                                    ? _buildEditableItemList(
                                        commonAllergens, selectedAllergens)
                                    : _buildItemList(
                                        selectedAllergens,
                                        'No allergens selected',
                                      ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                    'Your Preferred Ingredients'),
                                isEditing
                                    ? _buildEditableItemList(
                                        preferredIngredients, selectedPreferred)
                                    : _buildItemList(
                                        selectedPreferred,
                                        'No preferred ingredients selected',
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
