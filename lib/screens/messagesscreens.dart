import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  List<Map<String, String>> _notifications = []; // List of notifications

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.getToken().then((token) {
      print('FCM Token: $token');
    });
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    print('User granted permission: ${settings.authorizationStatus}');

    try {
      await _firebaseMessaging.subscribeToTopic('all');
      print('Successfully subscribed to topic: all');
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title} - ${message.notification?.body}');
      if (message.notification != null) {
        _addNotification(
          message.notification!.title ?? 'No Title',
          message.notification!.body ?? 'No Message',
        );
        _showSystemNotification(message);
      }
    });

    // Handle notification clicks
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title} - ${message.notification?.body}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationPage(notifications: _notifications),
        ),
      );
    });
  }

  void _addNotification(String title, String body) {
    setState(() {
      _notifications.insert(0, {'title': title, 'body': body}); // Add to the top of the list
    });
  }

  // Show a notification at the top
  void _showSystemNotification(RemoteMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.notification?.title ?? 'No Title'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to the NotificationPage when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationPage(notifications: _notifications),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Push Notifications"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Manually navigate to NotificationPage to view notifications
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationPage(notifications: _notifications),
              ),
            );
          },
          child: Text('View All Notifications'),
        ),
      ),
    );
  }
}

class NotificationPage extends StatelessWidget {
  final List<Map<String, String>> notifications;

  NotificationPage({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification List"),
      ),
      body: notifications.isEmpty
          ? Center(child: Text("No notifications yet!"))
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 5,
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                notification['title'] ?? 'No Title',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(notification['body'] ?? 'No Message'),
            ),
          );
        },
      ),
    );
  }
}
