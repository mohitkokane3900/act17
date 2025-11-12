import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _bg(RemoteMessage m) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_bg);
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: FcmHome()));
}

class FcmHome extends StatefulWidget {
  const FcmHome({super.key});
  @override
  State<FcmHome> createState() => _FcmHomeState();
}

class _FcmHomeState extends State<FcmHome> {
  final fm = FirebaseMessaging.instance;
  String token = '';
  final List<Map<String, String>> inbox = [];

  @override
  void initState() {
    super.initState();
    _initFcm();
  }

  Future<void> _initFcm() async {
    await fm.requestPermission();
    await fm.subscribeToTopic('messaging');
    final t = await fm.getToken();
    setState(() {
      token = t ?? '';
    });
    FirebaseMessaging.onMessage.listen((m) {
      final title = m.notification?.title ?? 'Notification';
      final body = m.notification?.body ?? '';
      setState(() {
        inbox.insert(0, {'title': title, 'body': body, 'type': 'regular'});
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final title = m.notification?.title ?? 'Opened';
      final body = m.notification?.body ?? '';
      setState(() {
        inbox.insert(0, {'title': title, 'body': body, 'type': 'regular'});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FCM Basic')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('FCM Token'),
            const SizedBox(height: 6),
            SelectableText(token, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Inbox')),
            const SizedBox(height: 8),
            Expanded(
              child: inbox.isEmpty
                  ? const Center(child: Text('No messages yet'))
                  : ListView.builder(
                      itemCount: inbox.length,
                      itemBuilder: (c, i) {
                        final n = inbox[i];
                        return Card(
                          child: ListTile(
                            title: Text(n['title'] ?? ''),
                            subtitle: Text(n['body'] ?? ''),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
