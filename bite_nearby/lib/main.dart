import 'package:bite_nearby/screens/menu/CartProvider.dart';
import 'package:bite_nearby/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bite_nearby/screens/wrapper.dart';
import 'package:provider/provider.dart';
import 'package:bite_nearby/screens/models/user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bite_nearby/services/FeedbackService.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bite_nearby/screens/Order/FeedbackScreen.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Notification channel setup
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'feedback_channel',
  'Feedback Notifications',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'feedback_request') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => FeedbackScreen(
          orderId: message.data['orderId']!,
          restaurantName: message.data['restaurantName']!,
          orderItems: [],
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        Provider(create: (_) => FeedbackService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandlers();
    _checkForInitialNotification();
  }

  void _setupNotificationHandlers() {
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'feedback_request') {
        _showFeedbackScreen(
          message.data['orderId']!,
          message.data['restaurantName']!,
        );
      }
    });

    // Handle background notifications when app is reopened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'feedback_request') {
        _showFeedbackScreen(
          message.data['orderId']!,
          message.data['restaurantName']!,
        );
      }
    });
  }

  Future<void> _checkForInitialNotification() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null && message.data['type'] == 'feedback_request') {
      _showFeedbackScreen(
        message.data['orderId']!,
        message.data['restaurantName']!,
      );
    }
  }

  void _showFeedbackScreen(String orderId, String restaurantName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => FeedbackScreen(
            orderId: orderId,
            restaurantName: restaurantName,
            orderItems: [],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserObj?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        home: Wrapper(),
        navigatorKey: navigatorKey,
      ),
    );
  }
}
