import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:affiliate_portal_sdk/afflicate_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional: pass launch URL for click_id (e.g. from Linking.getInitialURL())
  // Afflicate.setLaunchUrl(await Linking.getInitialURL());
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
      appBar: AppBar(title: const Text('Afflicate SDK')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Attributed: ${result.attributed}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (result.affiliateCode != null)
              Text('Affiliate code: ${result.affiliateCode}'),
            if (result.matchMethod != null)
              Text('Match: ${result.matchMethod}'),
            if (result.matchConfidence != null)
              Text('Confidence: ${result.matchConfidence}%'),
          ],
        ),
      ),
    );
  }
}
