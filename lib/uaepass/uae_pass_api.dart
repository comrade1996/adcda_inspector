import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:adcda_inspector/uaepass/uaepass_user_profile_model.dart';
import 'package:adcda_inspector/uaepass/constant.dart';
import 'package:adcda_inspector/uaepass/memory_service.dart';
import 'package:adcda_inspector/uaepass/uaepass_view.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';

class UaePassAPI {
  final String _clientId;
  final String _callbackUrl;
  final String _clientSecrete;
  final String _language;
  final String _serviceProviderEnglishName;
  final String _serviceProviderArabicName;
  final bool _isProduction;
  final bool _blockSOP1;

  UaePassAPI({
    required String clientId,
    required String callbackUrl,
    required String clientSecrete,
    String serviceProviderEnglishName = 'Service Provider',
    String serviceProviderArabicName = 'مزود الخدمة',
    required bool isProduction,
    bool blockSOP1 = false,
    String language = 'en',
  })  : _clientId = clientId,
        _callbackUrl = callbackUrl,
        _clientSecrete = clientSecrete,
        _serviceProviderEnglishName = serviceProviderEnglishName,
        _serviceProviderArabicName = serviceProviderArabicName,
        _isProduction = isProduction,
        _blockSOP1 = blockSOP1,
        _language = language;

  Future<String> _getURL() async {
    // Initialize and clear previous ephemeral values
    await MemoryService.instance.initialize();
    await MemoryService.instance.clear();

    // Generate random state and PKCE code verifier/challenge
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    String randomString(int length) => List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
    final String state = randomString(32);
    final String codeVerifier = randomString(64);
    final String codeChallenge = base64Url
        .encode(sha256.convert(utf8.encode(codeVerifier)).bytes)
        .replaceAll('=', '');

    // Persist for callback/token exchange
    MemoryService.instance.state = state;
    MemoryService.instance.codeVerifier = codeVerifier;

    String acr = Const.uaePassMobileACR;
    String acrWeb = Const.uaePassWebACR;

    // Check if UAE PASS app installed; if not, use web ACR
    bool withApp = await canLaunchUrlString('${Const.uaePassScheme(_isProduction)}digitalid-users-ids');
    if (!withApp) {
      acr = acrWeb;
    }

    return "${Const.baseUrl(_isProduction)}/idshub/authorize?"
        "response_type=code"
        "&client_id=$_clientId"
        "&scope=urn:uae:digitalid:profile:general"
        "&state=$state"
        "&redirect_uri=$_callbackUrl"
        "&ui_locales=$_language"
        "&acr_values=$acr"
        "&code_challenge=$codeChallenge"
        "&code_challenge_method=S256";
  }

  Future<String?> signIn(BuildContext context) async {
    await MemoryService.instance.initialize();
    String url = await _getURL();
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomWebView(
            url: url,
            callbackUrl: _callbackUrl,
            isProduction: _isProduction,
            locale: _language,
          ),
        ),
      );
      return MemoryService.instance.accessCode;
    }
    return MemoryService.instance.accessCode;
  }

  Future<String?> getAccessToken(String code) async {
    try {
      const String url = "/idshub/token";

      var data = {
        'redirect_uri': _callbackUrl,
        'client_id': _clientId,
        'client_secret': _clientSecrete,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': MemoryService.instance.codeVerifier ?? '',
      };

      final response = await http
          .post(
            Uri.parse(Const.baseUrl(_isProduction) + url),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: data,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['access_token'] as String?;
      } else {
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(s);
      }
    }
    finally {
      // Clear ephemeral data
      try {
        await MemoryService.instance.clear();
      } catch (_) {}
    }
    return null;
  }

  Future<UAEPASSUserProfile?> getUserProfile(String token, {required BuildContext context}) async {
    try {
      const String url = "/idshub/userinfo";

      final response = await http
          .get(
            Uri.parse(Const.baseUrl(_isProduction) + url),
            headers: <String, String>{
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final profile = UAEPASSUserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);

        if (_blockSOP1 && profile.userType == 'SOP1') {
          debugPrint('UAEPASS >> UNAUTHORISED >> ${profile.userType} ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _language == 'ar'
                    ? 'أنت غير مؤهل للوصول إلى هذه الخدمة. إما أن حسابك لم تتم ترقيته أو لديك حساب زائر. يرجى الاتصال بـ $_serviceProviderArabicName لتتمكن من الوصول إلى الخدمة.'
                    : 'You are not eligible to access this service. Your account is either not upgraded or you have a visitor account. Please contact $_serviceProviderEnglishName to access the services.',
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );

          return null;
        }
        return profile;
      } else {
        return null;
      }
    } catch (e, s) {
      if (kDebugMode) {
        // ignore: avoid_print
        print(e);
        // ignore: avoid_print
        print(s);
      }
    }
    return null;
  }

  Future logout(BuildContext context) async {
    String url = "${Const.baseUrl(_isProduction)}/idshub/logout?redirect_uri=$_callbackUrl";

    if (context.mounted) {
      return await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomWebView(
            url: url,
            callbackUrl: _callbackUrl,
            isProduction: _isProduction,
            locale: _language,
          ),
        ),
      );
    }

    return null;
  }
}
