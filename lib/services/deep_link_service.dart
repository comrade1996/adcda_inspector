import 'dart:async';
import 'package:get/get.dart';
import 'package:uni_links/uni_links.dart';
import 'package:adcda_inspector/services/logging_service.dart';

class DeepLinkService extends GetxService {
  final LoggingService _logger = LoggingService();
  StreamSubscription? _linkSubscription;
  final RxString currentLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initUniLinks();
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initUniLinks() async {
    try {
      // Handle initial URI if the app was launched from a deep link
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _logger.info('App launched from deep link: $initialLink');
        _handleDeepLink(initialLink);
      }

      // Listen to incoming links while the app is running
      _linkSubscription = linkStream.listen((String? link) {
        if (link != null) {
          _logger.info('Received deep link while app running: $link');
          _handleDeepLink(link);
        }
      }, onError: (err) {
        _logger.error('Deep link error', err);
      });
    } catch (e) {
      _logger.error('Failed to initialize deep links', e);
    }
  }

  void _handleDeepLink(String link) {
    currentLink.value = link;
    
    // Handle UAE Pass callback URLs
    if (link.startsWith('adcdainspector://success')) {
      _logger.info('Received UAE Pass success callback');
      // The code parameter will be handled by the UAE Pass SDK
    } else if (link.startsWith('adcdainspector://failure')) {
      _logger.error('Received UAE Pass failure callback');
      // The error parameter will be handled by the UAE Pass SDK
    }
  }
}
