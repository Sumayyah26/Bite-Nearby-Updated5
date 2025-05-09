import 'package:flutter/material.dart';
import 'package:bite_nearby/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bite_nearby/screens/home/prefrences.dart';
import 'package:bite_nearby/screens/home/OrdersPage.dart';
import 'package:bite_nearby/screens/home/Restaurants.dart';
import 'package:bite_nearby/services/location.dart';
import 'package:bite_nearby/Coolors.dart';
import 'package:bite_nearby/screens/Order/FeedbackListener.dart';
import 'package:bite_nearby/screens/menu/MenuPage.dart';
import 'package:bite_nearby/services/Restaurant_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bite_nearby/main.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void _showRestaurantScreenGlobal(String restaurantId) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MenuPage(
          restaurantId: restaurantId,
          restaurantName: '',
        ),
      ),
    );
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Home> {
  final AuthService _auth = AuthService();
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String? _currentLocation;
  bool _isFetchingLocation = false;
  Map<String, dynamic>? _nearestRestaurant;
  bool _isLoadingRestaurant = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _fetchNearestRestaurant();
    FeedbackListenerService.initialize(context);

    // Show notification immediately when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _showImmediateNotificationWithItem();
    });

    // Then start regular monitoring
    LocationService().startProximityMonitoring();
  }

  Future<List<Map<String, dynamic>>> _getPopularItems(
      String restaurantId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Restaurants')
          .doc(restaurantId)
          .collection('menu')
          .orderBy('rating', descending: true)
          .limit(1)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      return [];
    }
  }

  Future<void> _showImmediateNotificationWithItem() async {
    if (_nearestRestaurant == null) return;

    final items = await _getPopularItems(_nearestRestaurant!['id']);
    if (items.isEmpty) return;

    final featuredItem = items.first;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'proximity_channel',
      'Proximity Alerts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      _nearestRestaurant!['id'].hashCode,
      'Try ${featuredItem['Name']} at ${_nearestRestaurant!['name']}!',
      'Our most popular item is just waiting for you!',
      platformChannelSpecifics,
      payload: 'restaurant:${_nearestRestaurant!['id']}',
    );
  }

  Future<void> _showProximityNotificationWithItems() async {
    if (_nearestRestaurant == null) return;

    final items =
        await LocationService().getPopularItems(_nearestRestaurant!['id']);
    if (items.isEmpty) return;

    final featuredItem = items.first;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'proximity_channel',
      'Proximity Alerts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      _nearestRestaurant!['id'].hashCode,
      'Special at ${_nearestRestaurant!['name']}',
      'Don\'t miss ${featuredItem['Name']} at ${_nearestRestaurant!['name']}!',
      platformChannelSpecifics,
      payload: 'restaurant:${_nearestRestaurant!['id']}',
    );
  }

  Future<void> _fetchNearestRestaurant() async {
    setState(() {
      _isLoadingRestaurant = true;
    });

    try {
      RestaurantService restaurantService = RestaurantService();
      List<Map<String, dynamic>> restaurants =
          await restaurantService.getSortedRestaurants();

      if (restaurants.isNotEmpty) {
        setState(() {
          _nearestRestaurant = restaurants.first;
          _isLoadingRestaurant = false;
        });
      } else {
        setState(() {
          _isLoadingRestaurant = false;
        });
      }
    } catch (e) {
      print('Error fetching nearest restaurant: $e');
      setState(() {
        _isLoadingRestaurant = false;
      });
    }
  }

  Future<String?> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (snapshot.exists) {
          String username = snapshot.get('username') ?? 'User';
          return username.trim().isNotEmpty ? username : 'User';
        }
      } catch (e) {
        print('Error fetching username: $e');
      }
    }
    return "Guest";
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      LocationService locationService = LocationService();
      Map<String, dynamic> locationData =
          await locationService.getCurrentLocation();

      setState(() {
        _currentLocation = " ${locationData['address']}";
        _isFetchingLocation = false;
      });
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        _currentLocation = "Location unavailable";
        _isFetchingLocation = false;
      });
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Widget _buildHeader(String title) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Coolors.charcoalBlack,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back,",
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 14,
                        color: Coolors.lightOrange.withOpacity(0.7),
                      )),
                  SizedBox(height: 10),
                  FutureBuilder<String?>(
                    future: _getUsername(),
                    builder: (context, snapshot) => Text(
                      snapshot.data ?? "Guest",
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Coolors.lightOrange,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                      color: Coolors.oliveGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Coolors.oliveGreen),
                        SizedBox(width: 4),
                        SizedBox(
                          width: 200,
                          child: Text(
                            _currentLocation ?? "Locating...",
                            style: TextStyle(
                              fontSize: 10,
                              color: Coolors.oliveGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async => await _auth.signOut(),
                    icon: Icon(Icons.logout,
                        size: 18, color: Coolors.lightOrange),
                    label: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        color: Coolors.lightOrange,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNearestRestaurantCard() {
    if (_isLoadingRestaurant) {
      return Center(
        child: CircularProgressIndicator(
          color: Coolors.wineRed,
        ),
      );
    }

    if (_nearestRestaurant == null) {
      return Center(
        child: Text(
          'No nearby restaurants found',
          style: TextStyle(
            color: Coolors.charcoalBlack,
            fontSize: 16,
          ),
        ),
      );
    }

    // Get the image URL - try restaurant_image first, then fallback to image_url
    String? imageUrl = _nearestRestaurant!['restaurant_image'] ??
        _nearestRestaurant!['image_url'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        margin: EdgeInsets.only(top: 20, bottom: 20),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nearestRestaurant!['name'] ?? 'Unnamed Restaurant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Coolors.charcoalBlack,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Coolors.gold, size: 20),
                      SizedBox(width: 4),
                      Text(
                        _nearestRestaurant!['rating']?.toStringAsFixed(1) ??
                            'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          color: Coolors.charcoalBlack.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.location_on, color: Coolors.wineRed, size: 20),
                      SizedBox(width: 4),
                      Text(
                        "${(_nearestRestaurant!['distance'] / 1000).toStringAsFixed(1)} km",
                        style: TextStyle(
                          fontSize: 16,
                          color: Coolors.charcoalBlack.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuPage(
                              restaurantId: _nearestRestaurant!['id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Coolors.wineRed,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Explore Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coolors.ivoryCream,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: onTabTapped,
          children: [
            Column(
              children: [
                _buildHeader(""),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 20, top: 10),
                          child: Text(
                            'Nearest Restaurant',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Coolors.charcoalBlack,
                              fontFamily: 'Times New Roman',
                            ),
                          ),
                        ),
                        _buildNearestRestaurantCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const PreferencesPage(),
            OrdersPage(
              orderId: '',
              restaurantName: 'All Restaurants',
            ),
            const RestaurantListPage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Coolors.charcoalBlack,
          borderRadius: BorderRadius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Coolors.gold,
          unselectedItemColor: Coolors.ivoryCream,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 30), // increased size
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Dietary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Restaurants',
            ),
          ],
        ),
      ),
    );
  }
}
