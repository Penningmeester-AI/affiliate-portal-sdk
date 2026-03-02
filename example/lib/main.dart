import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:affiliate_portal_sdk/afflicate_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appLinks = AppLinks();
  final uri = await appLinks.getInitialLink();
  Afflicate.setLaunchUrl(uri?.toString());
  await Afflicate.init(AfflicateConfig(
    publicKey: 'pk_live_xxx',
    appId: 'com.example.affiliate_portal_sdk_example',
    consentGiven: true,
    debug: kDebugMode,
  ));
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afflicate SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final result = Afflicate.getAttribution();
    return Scaffold(
      appBar: AppBar(title: const Text('Afflicate Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attributed: ${result.attributed}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Affiliate Code: ${result.affiliateCode ?? 'None'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (result.matchMethod != null)
              Text('Match: ${result.matchMethod}'),
            if (result.matchConfidence != null)
              Text('Confidence: ${result.matchConfidence}%'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('Signup with code: ${result.affiliateCode}');
              },
              child: const Text('Simulate Signup'),
            ),
          ],
        ),
      ),
    );
  }
}
