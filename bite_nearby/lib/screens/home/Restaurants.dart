import 'package:bite_nearby/services/Restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:bite_nearby/screens/menu/MenuPage.dart';
import 'package:bite_nearby/Coolors.dart'; // Make sure to import your colors

class RestaurantListPage extends StatefulWidget {
  const RestaurantListPage({super.key});

  @override
  _RestaurantListPageState createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Map<String, dynamic>> sortedRestaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
    try {
      List<Map<String, dynamic>> restaurants =
          await _restaurantService.getSortedRestaurants();

      setState(() {
        sortedRestaurants = restaurants;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching restaurants: $e");
      setState(() => isLoading = false);
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
      child: Center(
        child: Text(
          'Restaurants',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Coolors.lightOrange,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
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
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 16),
                    itemCount: sortedRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = sortedRestaurants[index];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuPage(
                                restaurantId: restaurant['id'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Restaurant Image
                              if (restaurant['image_url'] != null &&
                                  restaurant['image_url'].isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    restaurant['image_url'],
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 50),
                                  ),
                                ),

                              // Restaurant Details
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            restaurant['name'] ??
                                                'Unnamed Restaurant',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (restaurant['rating'] != null)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Coolors.gold.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star,
                                                    size: 18,
                                                    color: Coolors.gold),
                                                SizedBox(width: 4),
                                                Text(
                                                  restaurant['rating']
                                                      .toStringAsFixed(1),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Coolors.charcoalBlack,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 16, color: Coolors.wineRed),
                                        SizedBox(width: 4),
                                        Text(
                                          "${(restaurant['distance'] / 1000).toStringAsFixed(2)} km away",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
