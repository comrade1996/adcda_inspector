import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';

class UaePassIntegrationExample extends StatefulWidget {
  const UaePassIntegrationExample({Key? key}) : super(key: key);

  @override
  State<UaePassIntegrationExample> createState() => _UaePassIntegrationExampleState();
}

class _UaePassIntegrationExampleState extends State<UaePassIntegrationExample> {
  final DeepLinkService _deepLinkService = DeepLinkService();
  String? _authCode;

  @override
  void initState() {
    super.initState();
    // Initialize deep link handling
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Register callback for UAE PASS authorization code
    _deepLinkService.registerUaePassCallback(_handleUaePassCode);
    
    // Initialize deep links
    await _deepLinkService.initDeepLinks();
  }

  void _handleUaePassCode(String code) {
    setState(() {
      _authCode = code;
    });
    
    // In a real app, you would exchange this code for a token
    // and complete the authentication process
    _exchangeCodeForToken(code);
  }

  Future<void> _exchangeCodeForToken(String code) async {
    // Example implementation - replace with your actual API call
    debugPrint('Exchanging code for UAE PASS token: $code');
    
    // In a real implementation, you would:
    // 1. Make an API call to your backend or directly to UAE PASS token endpoint
    // 2. Exchange the authorization code for an access token
    // 3. Validate the token and get user information
    // 4. Complete the authentication flow
  }

  void _initiateUaePassLogin() {
    // In a real app, you would open a browser or WebView with the UAE PASS authorization URL
    // The user would authenticate with UAE PASS, and UAE PASS would redirect back to your app
    // using the deep link scheme: adcdainspector://uaepass/callback?code=AUTHORIZATION_CODE
    
    debugPrint('Opening UAE PASS login page...');
    
    // Example of how to test the deep link (for demonstration purposes)
    debugPrint('To test, try opening this link in your browser:');
    debugPrint('adcdainspector://uaepass/callback?code=TEST123');
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UAE PASS Integration')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_authCode != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Authenticated with UAE PASS!\nAuthorization Code: $_authCode',
                  textAlign: TextAlign.center,
                ),
              )
            else
              const Text('Not authenticated with UAE PASS'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initiateUaePassLogin,
              child: const Text('Sign in with UAE PASS'),
            ),
          ],
        ),
      ),
    );
  }
}
