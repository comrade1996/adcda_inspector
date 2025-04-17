import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  // Singleton pattern
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // AppLinks instance
  final AppLinks _appLinks = AppLinks();
  
  // Stream subscription for handling incoming links
  StreamSubscription? _linkSubscription;
  
  // Callbacks
  Function(String code)? onUaePassCallback;

  // URI instance for initial link
  Uri? _initialUri;

  /// Initialize deep link handling
  Future<void> initDeepLinks() async {
    // Handle initial link (app was closed/not in foreground)
    try {
      _initialUri = await _appLinks.getInitialAppLink();
      if (_initialUri != null) {
        _handleDeepLink(_initialUri!);
      }
    } catch (e) {
      debugPrint('Error getting initial URI: $e');
    }

    // Listen for links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    }, onError: (error) {
      debugPrint('Error handling incoming links: $error');
    });
  }

  /// Handle deep link URI
  void _handleDeepLink(Uri uri) {
    // Check if this is a UAE PASS callback
    if (uri.host == 'uaepass' && uri.path == '/callback') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        debugPrint('Received UAE PASS authorization code: $code');
        // Notify callback if registered
        if (onUaePassCallback != null) {
          onUaePassCallback!(code);
        }
      }
    }
  }

  /// Register callback for UAE PASS authentication
  void registerUaePassCallback(Function(String code) callback) {
    onUaePassCallback = callback;
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
