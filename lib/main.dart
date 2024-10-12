import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp( MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const AlarmScreen(),
  ),
  );
}

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() {
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('app_icon');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    localNotifications.initialize(initializationSettings, onDidReceiveNotificationResponse: (response) {
      stopAlarm();  // Stop audio when notification is dismissed
    });
  }

  void startAlarm() async {
    await localNotifications.show(
      0,
      'Alarm',
      'The alarm is ringing!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('sound.mp3'),
        ),
      ),
    );

    playAlarmSound();
  }

  void playAlarmSound() async {
    audioPlayer.play(AssetSource('assets/sound.mp3'));  // Replace with your sound file
    await Future.delayed(const Duration(minutes: 4));  // Stop the alarm after 4 minutes if not dismissed
    stopAlarm();
  }

  void stopAlarm() {
    audioPlayer.stop();
    localNotifications.cancel(0);  // Cancel notification
  }

  void scheduleAlarm() async {
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 30), // Alarm rings after 30 seconds
      0,
      alarmCallback,  // Callback function to start the alarm
      wakeup: true,
    );
  }

  static Future<void> alarmCallback() async {
    FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    // Initialize settings for local notifications
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );
    await localNotifications.initialize(initializationSettings);
    await localNotifications.show(
      0,
      'Water Intake',
      'Time to drink water!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Notifications',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('alarm'),  // Your alarm sound in res/raw
        ),
      ),
    );
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(AssetSource('assets/sound.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reminder App"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            scheduleAlarm();  // Schedule alarm to ring after 30 seconds
          },
          child: Text('Set Alarm for 30 Seconds'),
        ),
      ),
    );
  }
}



