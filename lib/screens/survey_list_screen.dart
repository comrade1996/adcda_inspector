import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/survey_dto.dart' as dto;
import 'package:adcda_inspector/screens/survey_screen.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';

class SurveyListScreen extends StatefulWidget {
  final int defaultLanguageId;

  const SurveyListScreen({
    Key? key,
    required this.defaultLanguageId,
  }) : super(key: key);

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  final SurveyService _surveyService = SurveyService();
  List<dto.SurveyDTO> _surveys = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedLanguageId = 1; // Default to Arabic
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedLanguageId = _prefs.getInt('languageId') ?? 1;
    setState(() {});
  }

  Future<void> _loadSurveys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Make sure we're passing the current language ID to get properly localized surveys
      print('Loading surveys with language ID: $_selectedLanguageId');
      
      final surveyService = SurveyService();
      final surveys = await surveyService.fetchAllSurveys(languageId: _selectedLanguageId);
      
      setState(() {
        _surveys = surveys;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل الاستبيانات. يرجى المحاولة مرة أخرى'; // "Error loading surveys. Please try again later"
      });
      print('Error loading surveys: $e');
    }
  }

  Future<void> _changeLanguage(int languageId) async {
    print('Changing language to ID: $languageId from $_selectedLanguageId');
    
    // Only proceed if the language is actually changing
    if (languageId == _selectedLanguageId) {
      print('Language ID is the same, no change needed');
      return;
    }
    
    // Update UI first to show loading state
    setState(() {
      _selectedLanguageId = languageId;
      _isLoading = true;
      _surveys = []; // Clear existing surveys to force UI refresh
    });
    
    // Save the selected language as default
    await _prefs.setInt('languageId', languageId);
    print('Saved language ID $languageId to preferences');
    
    // Set the appropriate locale
    Locale newLocale;
    switch (languageId) {
      case 2:
        newLocale = const Locale('en');
        break;
      case 3:
        // Don't use country code for Urdu to avoid locale-related issues
        newLocale = const Locale('ur');
        break;
      case 1:
      default:
        newLocale = const Locale('ar');
        break;
    }
    
    print('Updating app locale to $newLocale');
    // Update app locale
    Get.updateLocale(newLocale);
    
    // Force a longer delay to ensure locale changes take effect
    await Future.delayed(Duration(milliseconds: 500));
    
    try {
      // Safely fetch surveys with the new language ID
      print('Fetching surveys with language ID: $languageId');
      
      // Create a new service instance each time to avoid caching issues
      final surveyService = SurveyService();
      
      try {
        final surveys = await surveyService.fetchAllSurveys(languageId: languageId);
        
        // Update UI with new surveys
        setState(() {
          _surveys = surveys;
          _isLoading = false;
          _errorMessage = '';
        });
        
        print('Successfully loaded ${surveys.length} surveys with language ID: $languageId');
      } catch (e) {
        // Handle error gracefully
        print('Error loading surveys: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل الاستبيانات. يرجى المحاولة مرة أخرى';
          _surveys = []; // Clear surveys to prevent null reference issues
        });
      }
    } catch (e) {
      print('Error in _changeLanguage: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء تحميل الاستبيانات. يرجى المحاولة مرة أخرى';
        _surveys = []; // Clear surveys to prevent null reference issues
      });
    }
  }

  String _getLanguageName(int languageId) {
    switch (languageId) {
      case 1:
        return 'Arabic';
      case 2:
        return 'English';
      case 3:
        return 'Urdu';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('surveysTitle'),
          style: const TextStyle(color: AppColors.whiteColor),
        ),
        backgroundColor: AppColors.primaryColor,
        centerTitle: false,
        actions: [
          // Language dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<int>(
              value: _selectedLanguageId,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: AppColors.darkBackgroundColor,
              style: const TextStyle(color: Colors.white),
              underline: Container(height: 0, color: Colors.transparent),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  _changeLanguage(newValue);
                }
              },
              items: [
                DropdownMenuItem<int>(
                  value: 1,
                  child: Text('العربية', style: const TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem<int>(
                  value: 2,
                  child: Text('English', style: const TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem<int>(
                  value: 3,
                  child: Text('اردو', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.whiteColor),
            onPressed: _loadSurveys,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.errorColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadSurveys,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_surveys.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('noDataAvailable'),
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSurveys,
      color: AppColors.primaryColor,
      child: ListView.builder(
        itemCount: _surveys.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final survey = _surveys[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: survey.isActive 
                  ? () {
                      Get.to(() => SurveyScreen(
                        surveyId: survey.id,
                        languageId: _selectedLanguageId,
                      ));
                    }
                  : null, // Disable tap for inactive surveys
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            survey.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (survey.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context).translate('activeStatus'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'NotoKufiArabic',
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context).translate('inactiveStatus'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'NotoKufiArabic',
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (survey.description != null && survey.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          survey.description!,
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Language: ${_getLanguageName(_selectedLanguageId)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: survey.isActive 
                              ? () {
                                  Get.to(() => SurveyScreen(
                                    surveyId: survey.id,
                                    languageId: _selectedLanguageId,
                                  ));
                                }
                              : null, // Disable button for inactive surveys
                          style: ElevatedButton.styleFrom(
                            backgroundColor: survey.isActive ? AppColors.primaryColor : Colors.grey,
                            foregroundColor: Colors.white,
                            elevation: survey.isActive ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Start Survey'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
