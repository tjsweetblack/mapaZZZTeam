import 'dart:async';
import 'dart:convert';
import 'package:auth_bloc/api/firebase_api.dart';
import 'package:auth_bloc/cubits/language_cubit.dart';
import 'package:auth_bloc/firebase_options.dart';
import 'package:auth_bloc/l10n/app_localizations.dart';
import 'package:auth_bloc/logic/cubit/auth_cubit.dart';
import 'package:auth_bloc/screens/splash_screen/splash.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import cloud_firestore
import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routing/app_router.dart';
import 'routing/routes.dart';
import 'theming/colors.dart';
import 'package:flutter_inappwebview/src/in_app_webview/in_app_webview.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localization/flutter_localization.dart';



late String initialRoute;

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message ${message.messageId}');
  print('Message data: ${message.data}');
  // You can perform background tasks here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
  ]);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  if (!onboardingCompleted) {
    initialRoute = Routes.onboardingScreen;
  } else {
    // Using a Completer to wait for the auth state to be determined
    final completer = Completer<void>();
    FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user == null || !user.emailVerified) {
          initialRoute = Routes.loginScreen;
        } else {
          initialRoute = Routes.mainScreen;
        }
        // Complete the completer once the initial route is set
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    // Wait for the completer to complete before running the app
    await completer.future;
  }

  runApp(
    DevicePreview(
      enabled: true, // kDebugMode,
      builder: (context) => MyApp(router: AppRouter()),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppRouter router;
  const MyApp({super.key, required this.router});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _riskZones = [];
  Timer? _locationCheckTimer;

  Future<List<Map<String, dynamic>>> _fetchRiskZones() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection('zones')
              .doc('87XfsZASiHtEwk1GEdO6')
              .get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data();
        if (data != null &&
            data.containsKey('zones') &&
            data['zones'] is List) {
          final zones = data['zones'] as List;
          print('all the zone are belows:');
          print(zones);
          return (data['zones'] as List).cast<Map<String, dynamic>>();
        } else {
          print(
              "Error: 'zones' field not found or is not a list in the document.");
          return [];
        }
      } else {
        print(
            "Error: Document '87XfsZASiHtEwk1GEdO6' does not exist in the 'zones' collection.");
        return [];
      }
    } catch (e) {
      print("Error fetching risk zones: $e");
      return [];
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<void> _checkProximityAndNotify() async {
    print("initiated proximity function");
    try {
      Position position = await _getCurrentLocation();
      int highestRiskLevel = 0; // Initialize risk level to 0 (no risk)

      for (var zone in _riskZones) {
        if (zone.containsKey('latitude') &&
            zone.containsKey('longitude') &&
            zone.containsKey('riskLevel')) {
          final double? zoneLat = zone['latitude'] as double?;
          final double? zoneLon = zone['longitude'] as double?;
          final int? zoneRiskLevel = zone['riskLevel'] as int?;

          if (zoneLat != null && zoneLon != null && zoneRiskLevel != null) {
            double distance = _calculateDistance(
              position.latitude,
              position.longitude,
              zoneLat,
              zoneLon,
            );

            // Check if the user is within 300 meters of this zone
            if (distance <= 300) {
              print(
                  "User is within 300m of a zone with risk level: $zoneRiskLevel");
              // Update highestRiskLevel if the current zone's level is higher
              if (zoneRiskLevel > highestRiskLevel) {
                highestRiskLevel = zoneRiskLevel;
              }
            }
          } else {
            print(
                "Warning: Invalid zone data - missing latitude, longitude, or riskLevel.");
          }
        } else {
          print(
              "Warning: Zone data missing expected keys (latitude, longitude, riskLevel).");
        }
      }
      _showProximityNotification(highestRiskLevel);
    } catch (e) {
      print("Error checking proximity: $e");
      // Handle location errors gracefully
    }
  }

  Future<void> _showProximityNotification(int riskLevel) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'proximity_channel', // Unique channel ID
      'Proximity Alerts', // Channel name
      channelDescription: 'Notifications for proximity to risk zones',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    String notificationMessage;
    switch (riskLevel) {
      case 1:
        notificationMessage = 'Estás em uma zona de baixo risco.';
        break;
      case 2:
        notificationMessage = 'Estás em uma zona de médio risco.';
        break;
      case 3:
        notificationMessage = 'Estás em uma zona de alto risco.';
        break;
      default: // riskLevel is 0 or any other unexpected value
        notificationMessage = 'Estás em uma área sem risco.';
        break;
    }

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Risco', // Notification Title
      notificationMessage, // Notification Body (the specific risk message)
      platformChannelSpecifics,
      payload: 'proximity_notification',
    );
  }

  Future<void> setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.instance.getToken().then((token) {
      print("FCM Token: $token");
      // Save this token to your server if needed
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        FirebaseApi().showLocalNotification(message);
      } else {
        print('Received a data-only message in foreground.');
        FirebaseApi().showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
      print('Message data: ${message.data}');
      // Handle navigation
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print(
            'App launched from terminated state by notification: ${message.data}');
        // Handle navigation
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Replace 'app_icon'
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initLocalNotifications();
    setupPushNotifications();
    _startLocationMonitoring(); // Start monitoring after initialization
  }

  Future<void> _initializeApp() async {
    // Fetch risk zones first
    _riskZones = await _fetchRiskZones();

    // Now that zones are fetched, perform the initial proximity check
    await _checkProximityAndNotify();

    // Delay for splash screen (adjust as needed)
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startLocationMonitoring() {
    // The initial check is now done in _initializeApp after fetching zones.
    _locationCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkProximityAndNotify();
    });
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
        BlocProvider<LanguageCubit>(create: (_) => LanguageCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return _isLoading
            ? const SplashScreen()
            : BlocBuilder<LanguageCubit, LanguageState>(
                builder: (context, state) {
                  return MaterialApp(
                    locale: state.locale,
                    localizationsDelegates: AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localeResolutionCallback: (locale, supportedLocales) {
                      return supportedLocales.contains(locale) ? locale : const Locale('en');
                    },
                    builder: DevicePreview.appBuilder,
                    onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
                    theme: ThemeData(
                      useMaterial3: true,
                      textSelectionTheme: const TextSelectionThemeData(
                        cursorColor: ColorsManager.mainBlue,
                        selectionColor: Color.fromARGB(188, 36, 124, 255),
                        selectionHandleColor: ColorsManager.mainBlue,
                      ),
                    ),
                    onGenerateRoute: widget.router.generateRoute,
                    debugShowCheckedModeBanner: false,
                    initialRoute: initialRoute,
                  );
                },
              );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AppRouter>('router', widget.router));
  }
}
