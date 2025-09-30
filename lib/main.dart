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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_ios/google_maps_flutter_ios.dart';
import 'routing/app_router.dart';
import 'routing/routes.dart';
import 'theming/colors.dart';

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

  // Lock app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Google Maps Flutter for both platforms
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    // Initialize for Android
    mapsImplementation.useAndroidViewSurface = true;
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  } else if (mapsImplementation is GoogleMapsFlutterIOS) {
    // Initialize for iOS - the API key should be set in Info.plist
    // No additional initialization required for iOS as it uses Info.plist
  }

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
    // Add a timeout to avoid hanging forever
    await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      initialRoute = Routes.loginScreen;
    });
  }

  runApp(
    DevicePreview(
      enabled: false, // kDebugMode,
      builder: (context) => MyApp(router: AppRouter()),
      isToolbarVisible: false,
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
      Position position = await _getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Location request timed out', const Duration(seconds: 10));
        },
      );

      print(
          "User location: LatLng(${position.latitude}, ${position.longitude})");

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

      String riskMessage;
      switch (highestRiskLevel) {
        case 1:
          riskMessage = 'Está numa zona de baixo risco.';
          break;
        case 2:
          riskMessage = 'Está numa zona de médio risco.';
          break;
        case 3:
          riskMessage = 'Está numa zona de alto risco.';
          break;
        default:
          riskMessage = 'Está numa zona sem risco.';
          break;
      }

      print("Risk level changed: $riskMessage");
      _showProximityNotification(highestRiskLevel);
    } catch (e) {
      print("Error checking proximity: $e");
      // Handle location errors gracefully - don't let this crash the app
      // Set a default state
      print("Risk level changed: Não foi possível determinar o risco.");
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
    try {
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

      // Handle token retrieval with proper error handling
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          print("FCM Token: $token");
          // Save this token to your server if needed
        } else {
          print("FCM Token is null - this is normal in iOS simulator");
        }
      } catch (tokenError) {
        print("Error getting FCM token (normal in simulator): $tokenError");
        // This is expected in iOS simulator - don't treat as fatal error
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print(
              'Message also contained a notification: ${message.notification}');
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
    } catch (e) {
      print("Error setting up push notifications (normal in simulator): $e");
      // Don't let Firebase messaging errors crash the app
    }
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
    print("MyApp initState started");
    _initializeAppSequentially();
  }

  Future<void> _initializeAppSequentially() async {
    try {
      print("Starting sequential initialization...");

      // Initialize local notifications first
      await _initLocalNotifications();
      print("Local notifications initialized");

      // Initialize Firebase messaging (with error handling)
      await setupPushNotifications();
      print("Push notifications setup completed");

      // Initialize the main app
      await _initializeApp();
      print("Main app initialization completed");

      // Start location monitoring after everything else is ready
      _startLocationMonitoring();
      print("Location monitoring started");

      print("All initialization completed successfully");
    } catch (e) {
      print("Error during sequential initialization: $e");
      // Ensure the app still shows even if initialization fails
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeApp() async {
    try {
      print("Starting main app initialization...");

      // Fetch risk zones first
      print("Fetching risk zones...");
      _riskZones = await _fetchRiskZones();
      print("Risk zones fetched: ${_riskZones.length} zones");

      // Now that zones are fetched, perform the initial proximity check
      print("Starting initial proximity check...");
      await _checkProximityAndNotify();
      print("Initial proximity check completed");

      // Delay for splash screen (adjust as needed)
      print("Waiting for splash screen duration...");
      await Future.delayed(const Duration(seconds: 3));
      print("Splash screen duration completed");

      if (mounted) {
        print("Setting app to loaded state...");
        setState(() {
          _isLoading = false;
        });
        print("App is now in loaded state - should show main screen");
      } else {
        print("Warning: Widget not mounted when trying to set loaded state");
      }
    } catch (e) {
      print("Error during app initialization: $e");
      // Even if there's an error, we should still show the main app
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print("App set to loaded state despite error");
      }
    }
  }

  void _startLocationMonitoring() {
    try {
      print("Starting location monitoring timer...");
      // The initial check is now done in _initializeApp after fetching zones.
      _locationCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        print("Periodic location check triggered");
        _checkProximityAndNotify();
      });
      print("Location monitoring timer started successfully");
    } catch (e) {
      print("Error starting location monitoring: $e");
    }
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
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
                      supportedLocales: AppLocalizations.supportedLocales,
                      localeResolutionCallback: (locale, supportedLocales) {
                        return supportedLocales.contains(locale)
                            ? locale
                            : const Locale('en');
                      },
                      builder: DevicePreview.appBuilder,
                      onGenerateTitle: (context) =>
                          AppLocalizations.of(context)!.appTitle,
                      theme: ThemeData(
                        useMaterial3: true,
                        textSelectionTheme: const TextSelectionThemeData(
                          cursorColor: ColorsManager.mainBlue,
                          selectionColor: Color.fromARGB(188, 36, 124, 255),
                          selectionHandleColor: ColorsManager.mainBlue,
                        ),
                        fontFamily: 'Poppins',
                        // You can customize other theme properties here as well.
                        primarySwatch: Colors.blue,
                        visualDensity: VisualDensity.adaptivePlatformDensity,
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
