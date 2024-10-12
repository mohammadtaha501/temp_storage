import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  _splashScreenState createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // Initialize the notification plugin
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _requestNotificationPermissions(context);
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Schedule the daily notification at 7 PM
    _scheduleDaily7PMNotification();
  }

  Future<void> _requestNotificationPermissions(BuildContext context) async {
    if (Platform.isIOS || Platform.isMacOS) {
      // Request permissions for iOS
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (Platform.isAndroid) {
      // Check the current status of the notification permission
      var status = await Permission.notification.status;

      if (status.isDenied) {
        // Request permission if it was previously denied
        await Permission.notification.request();

        // Check the status again after requesting
        status = await Permission.notification.status;
      }

      // Handle permission status
      if (status.isGranted) {
        // Permission is granted; you can schedule notifications
      } else if (status.isDenied) {
        // Show an alert or snackbar to inform the user
        _showPermissionDeniedDialog(context);
      } else if (status.isPermanentlyDenied) {
        // Show an alert or snackbar to inform the user
        _showPermissionPermanentlyDeniedDialog(context);
      }
    }
  }

// Method to show a dialog when permission is denied
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Denied'),
          content: Text('Notification permissions are required to receive alerts. Please enable notifications in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Method to show a dialog when permission is permanently denied
  void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Permanently Denied'),
          content: Text('Notification permissions have been permanently denied. Please enable them in app settings.'),
          actions: [
            TextButton(
              onPressed: () {
                // Optionally open app settings
                openAppSettings(); // Make sure to import permission_handler for this
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }



  // Function to schedule daily notifications at 7 PM
  Future<void> _scheduleDaily7PMNotification() async {
    // Specify the time (7:00 PM)
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime.local(now.year, now.month, now.day, 19);

    if (scheduledDate.isBefore(now)) {
      // If 7 PM has already passed today, schedule for tomorrow
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // Notification ID
      'Daily Reminder', // Title
      'Have you reached your daily drinking goal!', // Body
      scheduledDate, // The time to show the notification
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact, // Ensure notification is shown even when the device is idle
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time, // To repeat at 7 PM every day
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Notification at 7 PM'),
      ),
      body: const Center(
        child: Text('A notification will be shown daily at 7 PM'),
      ),
    );
  }
}
