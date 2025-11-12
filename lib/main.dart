import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _bg(RemoteMessage m) async {}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_bg);
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: FcmTypesHome()));
}

class FcmTypesHome extends StatefulWidget {
  const FcmTypesHome({super.key});
  @override
  State<FcmTypesHome> createState() => _FcmTypesHomeState();
}

class _FcmTypesHomeState extends State<FcmTypesHome> {
  final fm = FirebaseMessaging.instance;
  String token = '';
  String filter = 'All';
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
      final typ = (m.data['type'] ?? 'regular').toString().toLowerCase();
      setState(() {
        inbox.insert(0, {'title': title, 'body': body, 'type': typ});
      });
      if (mounted) {
        if (typ == 'important') {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.red.shade50,
              title: Text(title, style: const TextStyle(color: Colors.red)),
              content: Text(body),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK')),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(body)));
        }
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final title = m.notification?.title ?? 'Opened';
      final body = m.notification?.body ?? '';
      final typ = (m.data['type'] ?? 'regular').toString().toLowerCase();
      setState(() {
        inbox.insert(0, {'title': title, 'body': body, 'type': typ});
      });
    });
  }

  List<Map<String, String>> _filtered() {
    if (filter == 'All') return inbox;
    return inbox
        .where((n) => (n['type'] ?? 'regular') == filter.toLowerCase())
        .toList();
  }

  Color _tileColor(String t) {
    if (t == 'important') return Colors.red.shade50;
    return Colors.white;
  }

  Widget _typeChip(String t) {
    final active = filter == t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(t),
        selected: active,
        onSelected: (_) {
          setState(() {
            filter = t;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered();
    return Scaffold(
      appBar: AppBar(title: const Text('FCM Types')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
                alignment: Alignment.centerLeft, child: Text('FCM Token')),
            const SizedBox(height: 6),
            SelectableText(token, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeChip('All'),
                _typeChip('regular'),
                _typeChip('important'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No messages'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (c, i) {
                        final n = items[i];
                        final t = (n['type'] ?? 'regular').toLowerCase();
                        return Card(
                          color: _tileColor(t),
                          child: ListTile(
                            title: Text(n['title'] ?? ''),
                            subtitle: Text('${n['body'] ?? ''}\nType: $t'),
                            isThreeLine: true,
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
