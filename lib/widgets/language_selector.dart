import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:adcda_inspector/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A widget that displays a language selector dropdown in the app bar
class LanguageSelector extends StatefulWidget {
  final Function? onLanguageChanged;
  
  const LanguageSelector({
    Key? key,
    this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String currentLocale;
  
  @override
  void initState() {
    super.initState();
    // Get current locale or default to Arabic
    currentLocale = Get.locale?.languageCode ?? 'ar';
  }
  
  Future<void> _changeLanguage(String languageCode) async {
    if (languageCode == currentLocale) return;
    
    print('Changing language from $currentLocale to $languageCode');
    
    setState(() {
      currentLocale = languageCode;
    });
    
    // Save selected language to preferences
    final prefs = await SharedPreferences.getInstance();
    int languageId;
    
    switch (languageCode) {
      case 'en':
        languageId = AppConstants.englishLanguageId;
        break;
      case 'ur':
        languageId = AppConstants.urduLanguageId;
        break;
      case 'ar':
      default:
        languageId = AppConstants.arabicLanguageId;
        break;
    }
    
    await prefs.setInt('languageId', languageId);
    print('Saved language ID $languageId to preferences');
    
    // Update app locale
    final newLocale = Locale(languageCode);
    Get.updateLocale(newLocale);
    
    // Trigger callback if provided
    if (widget.onLanguageChanged != null) {
      widget.onLanguageChanged!();
    }
    
    // Refetch surveys (directly calling API)
    try {
      final surveyService = SurveyService();
      await surveyService.fetchAllSurveys(languageId: languageId);
      print('Successfully refetched surveys with language ID: $languageId');
    } catch (e) {
      print('Error refetching surveys after language change: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentLocale,
      icon: const Icon(Icons.language, color: Colors.white, size: 18),
      iconSize: 18,
      isDense: true,
      underline: Container(height: 0),
      onChanged: (String? newValue) {
        if (newValue != null && newValue != currentLocale) {
          _changeLanguage(newValue);
        }
      },
      dropdownColor: AppColors.darkBackgroundColor,
      items: [
        // Arabic option
        DropdownMenuItem<String>(
          value: 'ar',
          child: Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'العربية',
                    style: AppTheme.dropdownStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                _buildFlag('🇦🇪'),
              ],
            ),
          ),
        ),
        // English option
        DropdownMenuItem<String>(
          value: 'en',
          child: Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'English',
                    style: AppTheme.dropdownStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                _buildFlag('🇺🇸'),
              ],
            ),
          ),
        ),
        // Urdu option
        DropdownMenuItem<String>(
          value: 'ur',
          child: Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'اردو',
                    style: AppTheme.dropdownStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4),
                _buildFlag('🇵🇰'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlag(String emoji) {
    return Text(
      emoji,
      style: TextStyle(fontSize: 16),
    );
  }
}
