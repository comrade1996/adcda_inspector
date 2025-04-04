import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  static const supportedLocales = [
    Locale('ar'), // Arabic
    Locale('en'), // English
    Locale('ur'), // Urdu
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    try {
      // Load the language JSON file from the "l10n" folder
      String jsonString = await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      print('Error loading translations for ${locale.languageCode}: $e');
      // Fallback to Arabic if loading fails
      String jsonString = await rootBundle.loadString('lib/l10n/app_ar.arb');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      
      return true;
    }
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Get the localized month name
  String getMonth(int month) {
    assert(month >= 1 && month <= 12, 'Month value must be between 1 and 12');
    return translate('month$month');
  }

  // Format date in localized way
  String formatDate(DateTime date) {
    final String monthName = getMonth(date.month);
    if (locale.languageCode == 'ar' || locale.languageCode == 'ur') {
      // For right-to-left languages (Arabic and Urdu)
      return '${date.day} $monthName ${date.year}';
    } else {
      return '${date.day} $monthName ${date.year}';
    }
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['ar', 'en', 'ur'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
