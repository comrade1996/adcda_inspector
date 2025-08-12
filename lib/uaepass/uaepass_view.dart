import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:adcda_inspector/uaepass/memory_service.dart';
import 'package:adcda_inspector/uaepass/constant.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CustomWebView extends StatefulWidget {
  final String url;
  final String callbackUrl;
  final bool isProduction;
  final String locale;

  const CustomWebView({super.key, required this.url, required this.callbackUrl, required this.isProduction, this.locale = 'en'});

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late WebViewController controller;
  String? successUrl;
  late StreamSubscription<FGBGType> subscription;

  @override
  void dispose() {
    subscription.cancel();
    controller.clearLocalStorage();
    controller.clearCache();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    subscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.foreground) {
        if (successUrl != null) {
          final decoded = Uri.decodeFull(successUrl!);
          controller.loadRequest(Uri.parse(decoded));
        }
      }
    });
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..clearCache()
      ..clearLocalStorage()
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    super.initState();
  }

  Future<NavigationDecision> onNavigationRequest(NavigationRequest request) async {
    String url = request.url.toString();
    debugPrint('UAEPASS url: $url');
    if (url.contains('uaepass://')) {
      Uri uri = Uri.parse(url);
      String? successURL = uri.queryParameters['successurl'];
      successUrl = successURL;
      final newUrl = '${Const.uaePassScheme(widget.isProduction)}${uri.host}${uri.path}';
      String u = "$newUrl?successurl=${widget.callbackUrl}"
          "&failureurl=${widget.callbackUrl}"
          "&closeondone=true";
      await launchUrl(Uri.parse(u));
      return NavigationDecision.prevent;
    }

    // Handle callback with code (and verify state)
    if (url.startsWith(widget.callbackUrl) && url.contains('code=')) {
      final uri = Uri.parse(url);
      final String? code = uri.queryParameters['code'];
      final String? returnedState = uri.queryParameters['state'];
      final String? expectedState = MemoryService.instance.state;

      if (code == null) {
        return NavigationDecision.navigate;
      }

      // CSRF protection: verify state
      if (expectedState == null || returnedState == null || expectedState != returnedState) {
        debugPrint('UAEPASS >> State mismatch. expected=$expectedState, returned=$returnedState');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.locale == 'ar' ? 'خطأ في التحقق الأمني. حاول مرة أخرى.' : 'Security check failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
        if (mounted) Navigator.of(context).pop();
        return NavigationDecision.prevent;
      }

      MemoryService.instance.accessCode = code;
      debugPrint('UAEPASS code: $code');
      if (mounted) Navigator.of(context).pop(code);
      return NavigationDecision.prevent;
    } else if (url.contains('error=invalid_request') ||
        url.contains('error=login_required') ||
        url.contains('error=access_denied') ||
        url.contains('error=cancelledOnApp')) {
      debugPrint('UAEPASS >> User cancelled the login << ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.locale == 'ar' ? 'قام المستخدم بإلغاء تسجيل الدخول' : 'User cancelled the login'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );

      if (!url.contains('logout')) {
        if (mounted) Navigator.pop(context);
        return NavigationDecision.prevent;
      }
    } else if (url == widget.callbackUrl && widget.url.contains('logout')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.locale == 'ar' ? 'تم تسجيل الخروج بنجاح' : 'Successfully Logout'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      if (mounted) Navigator.pop(context);
      return NavigationDecision.prevent;
    } else if (url.startsWith(widget.callbackUrl) && url.contains('error=')) {
      final uri = Uri.parse(url);
      final err = uri.queryParameters['error'];
      final errDesc = uri.queryParameters['error_description'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errDesc ?? (widget.locale == 'ar' ? 'خطأ غير معروف في تسجيل الدخول' : 'Unknown login error')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('UAEPASS error: $err, description: $errDesc');
      if (mounted) Navigator.pop(context);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
