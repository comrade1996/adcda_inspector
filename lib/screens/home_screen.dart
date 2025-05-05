import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/screens/survey_screen.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:adcda_inspector/models/survey_dto.dart' as dto;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';
import 'package:adcda_inspector/widgets/language_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyItem {
  final int id;
  final String title;
  final String description;
  final String date;
  final String status;
  final Color statusColor;

  SurveyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  // Factory method to create a SurveyItem from a SurveyDTO
  factory SurveyItem.fromSurveyDTO(dto.SurveyDTO dto, BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context);
    
    // Determine status and color based on the survey's isActive property
    String status;
    Color statusColor;
    
    if (dto.isActive) {
      status = localizations.translate('activeStatus');
      statusColor = AppColors.activeColor;
    } else {
      status = localizations.translate('inactiveStatus');
      statusColor = AppColors.inactiveColor;
    }

    // Format the date from createdAt if available, otherwise use current date
    String date;
    if (dto.createdAt != null && dto.createdAt!.isNotEmpty) {
      try {
        final DateTime createdDate = DateTime.parse(dto.createdAt!);
        date = localizations.formatDate(createdDate);
      } catch (e) {
        // Fallback to current date if parsing fails
        date = localizations.formatDate(DateTime.now());
      }
    } else {
      // Use current date as fallback
      date = localizations.formatDate(DateTime.now());
    }

    return SurveyItem(
      id: dto.id,
      title: dto.name,
      description: dto.description ?? 'استبيان تقييم لمركز الدفاع المدني',
      date: date,
      status: status,
      statusColor: statusColor,
    );
  }
  
  // Helper method to get Arabic month name
  static String _getArabicMonth(int month) {
    final List<String> arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    
    return arabicMonths[month - 1];
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SurveyService _surveyService = SurveyService();
  bool _isLoading = false;
  bool _isLoadingData = true;
  List<SurveyItem> _surveys = [];
  String _errorMessage = '';
  int _currentLanguageId = AppConstants.defaultLanguageId;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedLanguageId = prefs.getInt('languageId') ?? AppConstants.defaultLanguageId;
      
      setState(() {
        _currentLanguageId = storedLanguageId;
      });
      
      _fetchSurveys();
    } catch (e) {
      print('Error loading language preference: $e');
      // Fall back to default language
      setState(() {
        _currentLanguageId = AppConstants.defaultLanguageId;
      });
      _fetchSurveys();
    }
  }

  void _handleLanguageChanged() {
    // Called when language is changed in the language selector
    _loadLanguagePreference().then((_) {
      // Reset UI with new language
      setState(() {});
    });
  }

  Future<void> _fetchSurveys() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = '';
    });

    try {
      final surveys = await _surveyService.fetchAllSurveys(
        languageId: _currentLanguageId
      );
      
      // Convert the API data to our UI model
      if (mounted) {
        setState(() {
          _surveys = surveys.map((dto) => SurveyItem.fromSurveyDTO(dto, context)).toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context).translate('errorLoadingData');
          _isLoadingData = false;
        });
      }
      print('Error fetching surveys: $e');
    }
  }

  void _startSurvey(int surveyId) {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Show loader for 2 seconds - more elegant loader
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Lottie.asset(
            'assets/images/loader.json',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    // Simulate loading with delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close dialog
      setState(() {
        _isLoading = false;
      });

      // Navigate to survey screen
      Get.to(() => SurveyScreen(
        surveyId: surveyId,
        languageId: _currentLanguageId,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF101010),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar with Title and Language Selector
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textDirection: TextDirection.rtl, // Ensure correct RTL layout
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Take only needed space
                        children: [
                          Image.asset(
                            'assets/images/adcda_logo.png',
                            height: 36,
                            width: 36,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              localizations.translate('appTitle'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18, // Slightly smaller font
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis, // Handle overflow
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min, // Take only needed space
                      children: [
                        LanguageSelector(
                          onLanguageChanged: _handleLanguageChanged,
                        ),
                        SizedBox(width: 4), // Reduced spacing
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white, size: 22),
                          onPressed: _fetchSurveys,
                          tooltip: localizations.translate('retry'),
                          constraints: BoxConstraints(minWidth: 36, minHeight: 36), // Compact size
                          padding: EdgeInsets.zero, // Remove padding
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Main content area
              Expanded(
                child: _isLoadingData
                    ? _buildLoadingView()
                    : _errorMessage.isNotEmpty
                        ? _buildErrorView()
                        : _surveys.isEmpty
                            ? _buildEmptyView()
                            : _buildSurveysList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/images/loader.json',
            width: 100,
            height: 100,
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل الاستبيانات...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.errorColor,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'NotoKufiArabic',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchSurveys,
            icon: Icon(Icons.refresh),
            label: Text(
              'إعادة المحاولة',
              style: TextStyle(
                fontFamily: 'NotoKufiArabic',
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد استبيانات متاحة حالياً',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveysList() {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _surveys.length,
      itemBuilder: (context, index) {
        final survey = _surveys[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _startSurvey(survey.id),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: survey.statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            survey.status,
                            style: TextStyle(
                              color: survey.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoKufiArabic',
                            ),
                          ),
                        ),
                        Text(
                          survey.date,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Title
                    Text(
                      survey.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Description
                    Text(
                      survey.description,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontFamily: 'NotoKufiArabic',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16),
                    
                    // Start button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () => _startSurvey(survey.id),
                        icon: Icon(Icons.play_arrow),
                        label: Text(
                          AppLocalizations.of(context).translate('startSurvey'),
                          style: TextStyle(
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (100 + index * 100).ms).slideY(begin: 0.2, end: 0);
      },
    );
  }
}
