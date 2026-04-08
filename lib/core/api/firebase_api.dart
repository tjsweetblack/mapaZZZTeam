import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

// Required for handling taps on foreground notifications from terminated state
// if you decide to add navigation logic triggered by notification taps later.
// You might need to define a global navigator key in your main app file
// if you plan to handle navigation from notification taps across your app.
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseApi {
  // instance
  final _firebaseMessaging = FirebaseMessaging.instance;
  // Local notifications plugin instance
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Function to initialize notification settings (Firebase & Local)
  Future<void> initNotifications() async {
    try {
      // --- Firebase Messaging Initialization ---
      // Request permission from user (enhanced for iOS)
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('FCM Permission status: ${settings.authorizationStatus}');

      // Fetch the FCM token with error handling (iOS APNS token fix)
      try {
        String? token;

        // For iOS, ensure APNS token is available first
        if (Platform.isIOS) {
          try {
            // Wait for APNS token to be available with retries
            String? apnsToken;
            int retryCount = 0;
            const maxRetries = 5;

            while (apnsToken == null && retryCount < maxRetries) {
              apnsToken = await _firebaseMessaging.getAPNSToken();
              if (apnsToken == null) {
                retryCount++;
                print(
                    'APNS Token not available yet, retrying... ($retryCount/$maxRetries)');
                await Future.delayed(Duration(seconds: retryCount));
              }
            }

            if (apnsToken != null) {
              print('APNS Token available: ${apnsToken.substring(0, 20)}...');
            } else {
              print(
                  'APNS Token not available after $maxRetries retries, proceeding anyway...');
            }

            token = await _firebaseMessaging.getToken();
          } catch (apnsError) {
            print(
                'APNS Token error: $apnsError, trying to get FCM token anyway...');
            token = await _firebaseMessaging.getToken();
          }
        } else {
          // For Android and other platforms
          token = await _firebaseMessaging.getToken();
        }

        if (token != null) {
          // Print the token
          print('FCM Token: $token');
          // Add the token to Firestore
          await _addTokenToFirestore(token);
        } else {
          print('FCM Token is null - this might be normal in iOS simulator');
        }
      } catch (tokenError) {
        print(
            'Error getting FCM token (might be normal in simulator): $tokenError');
        // Continue initialization even if token fails
      }

      // Listen for token refresh (important for iOS)
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await _addTokenToFirestore(newToken);
      });

      // Configure handling for foreground messages
      // This listener receives messages when the app is open and in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        // ** Call the local notification function to display the notification **
        if (message.notification != null) {
          print(
              'Message also contained a notification: ${message.notification}');
          showLocalNotification(
              message); // Call the method to show the local notification
        } else {
          // Handle data-only messages in foreground if needed
          print('Received a data-only message in foreground.');
          // You might still want to show a local notification based on data
          // showDataNotification(message.data); // Example: Implement this if needed
        }
      });
    } catch (e) {
      print(
          'Error initializing Firebase notifications (normal in simulator): $e');
      // Don't let Firebase initialization errors crash the app
    }

    // Configure handling for messages that open the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message opened app from background!');
      print('Message data: ${message.data}');
      // Handle navigation or other actions based on message.data
      // Example: navigate to a specific screen using message.data
      // navigatorKey.currentState?.pushNamed('/someRoute', arguments: message.data);
    });

    // Configure handling for messages that launch the app from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print(
            'App launched from terminated state by notification: ${message.data}');
        // Handle navigation or other actions based on message.data
        // This is called when the app is opened by tapping a notification
        // while the app was completely terminated.
        // Example: navigatorKey.currentState?.pushNamed('/someRoute', arguments: message.data);
      }
    });

    // --- Local Notifications Initialization ---
    // Configure platform-specific initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Use your app icon here

    // For iOS, request necessary permissions
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initializationSettings,
      // This callback is triggered when a foreground notification (shown by flutter_local_notifications) is tapped
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // Handle tap on foreground notification
        // The payload can be used to determine what action to take (e.g., navigate)
        print(
            'Local notification tapped. Payload: ${notificationResponse.payload}');
        // Example: navigate using the payload
        // navigatorKey.currentState?.pushNamed('/someRoute', arguments: notificationResponse.payload);
      },
      // Add other handlers if needed, like onDidReceiveBackgroundNotificationResponse
    );

    // Create a notification channel for Android (required for Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id: Must be unique for your app
      'High Importance Notifications', // title: User-visible title
      description:
          'This channel is used for important notifications.', // description: User-visible description
      importance: Importance.max, // Importance level
    );

    // Create the channel on the device
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print(
        "Firebase and flutter_local_notifications initialized."); // Added print for confirmation
  }

  // Method to add the FCM token to Firestore
  Future<void> _addTokenToFirestore(String token) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String documentId = 'c2PbPi31eheOSGuBKDor';
      final String collectionName = 'fcm';
      final String tokenFieldName = 'token';

      final DocumentReference documentReference =
          firestore.collection(collectionName).doc(documentId);

      // Check if the document exists before trying to update
      final docSnapshot = await documentReference.get();
      if (docSnapshot.exists) {
        // Get existing tokens to avoid duplicates
        final existingData = docSnapshot.data() as Map<String, dynamic>?;
        final existingTokens =
            existingData?[tokenFieldName] as List<dynamic>? ?? [];

        if (!existingTokens.contains(token)) {
          await documentReference.update({
            tokenFieldName: FieldValue.arrayUnion([token]),
          });
          print(
              'FCM Token "$token" successfully added to document "$documentId"');
        } else {
          print('FCM Token already exists in the array. No duplicate added.');
        }
      } else {
        // If the document doesn't exist, create it with the token
        await documentReference.set({
          tokenFieldName: [token], // Start a new array with the token
        });
        print('Document "$documentId" created and FCM token "$token" added');
      }
    } catch (e) {
      print('Error adding FCM token to Firestore: $e');
    }
  }

  // ** --- NEW METHOD TO SHOW LOCAL NOTIFICATION --- **
  void showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    // AppleNotification? apple = message.notification?.apple; // You can access this for iOS specific needs

    if (notification == null) {
      print("Cannot show local notification: message.notification is null.");
      return; // Exit if there's no notification payload
    }

    // ** --- CORRECTED: Wrap platform-specific details in NotificationDetails --- **

    // Define the platform-specific details
    AndroidNotificationDetails? androidDetails;

    if (android != null) {
      androidDetails = AndroidNotificationDetails(
        'high_importance_channel', // Same ID as the channel created in initNotifications
        'High Importance Notifications', // Same title as the channel
        channelDescription: 'This channel is used for important notifications.',
        icon:
            android.smallIcon, // Use the small icon provided by FCM (optional)
        // Set priority, visibility, etc. if needed
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    // For iOS, we generally don't need the DarwinNotificationDetails from message unless customizing deeply.
    // Basic iOS notification details are often configured during plugin initialization.
    // If you had specific iOS details in the FCM message (like sound), you might use:
    // iOSDetails = DarwinNotificationDetails(sound: apple?.sound);

    // Create the overall NotificationDetails object
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails, // Pass the Android details if available
      iOS: const DarwinNotificationDetails(
        // Use default iOS details or customize here
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      // Add other platforms here if necessary (e.g., macOS, Linux)
    );

    print("Attempting to show local notification..."); // Added print

    _localNotifications.show(
      notification.hashCode, // Use a unique ID. hashCode is often sufficient.
      notification.title,
      notification.body,
      platformChannelSpecifics, // Pass the wrapped NotificationDetails
      // Optional: add a payload to pass data when the notification is tapped
      // This data can be accessed in the onDidReceiveNotificationResponse callback
      payload: message.data['some_identifying_key']
          ?.toString(), // Example: Replace 'some_identifying_key'
    );
    print("Local notification show called."); // Added print
  }

  // Optional: Method to show a local notification for data-only messages
  /*
  void showDataNotification(Map<String, dynamic> data) {
      // Implement logic to create a NotificationDetails and call _localNotifications.show
      // based on the data content. You'll need to define a title, body, etc.
      print("Handling data-only message to show local notification...");
       if (data['title'] != null && data['body'] != null) {
          _localNotifications.show(
              data.hashCode, // Use a unique ID for the notification
              data['title'],
              data['body'],
              const NotificationDetails(
                 android: AndroidNotificationDetails(
                   'high_importance_channel', // Use your channel ID
                   'High Importance Notifications',
                   channelDescription: 'This channel is used for important notifications.',
                    icon: '@mipmap/ic_launcher', // Use your app icon
                    importance: Importance.max,
                    priority: Priority.high,
                 ),
                 iOS: DarwinNotificationDetails(
                     presentAlert: true,
                     presentBadge: true,
                     presentSound: true,
                 ),
              ),
               payload: data['some_identifier']?.toString(), // Example: pass identifier
          );
           print("Local notification shown from data-only message.");
      } else {
         print("Data-only message does not contain title or body to show notification.");
      }
  }
  */

  // Optional: Method to handle notification taps for terminated state (if using a global key)
  /*
  Future<void> handleInitialMessage() async {
     final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
     if (initialMessage != null) {
        print('App launched from terminated state by notification: ${initialMessage.data}');
        // Handle navigation based on initialMessage.data
         // Example: navigatorKey.currentState?.pushNamed('/someRoute', arguments: initialMessage.data);
     }
  }
  */
}
