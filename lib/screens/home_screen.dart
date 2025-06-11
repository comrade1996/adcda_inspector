import 'dart:convert';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/models/user_profile.dart';
import 'package:adcda_inspector/screens/login_screen.dart';
import 'package:adcda_inspector/screens/survey_screen.dart';
import 'package:adcda_inspector/services/auth_service.dart';
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
  final AuthService _authService = Get.find<AuthService>();
  bool _isLoading = false;
  bool _isLoadingData = true;
  List<SurveyItem> _surveys = [];
  String _errorMessage = '';
  int _currentLanguageId = AppConstants.defaultLanguageId;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _getUserProfile();
    
    // Add a delayed refresh to ensure we get the latest data after login
    Future.delayed(Duration(milliseconds: 500), () {
      _refreshUserProfile();
    });
  }
  
  // Method to explicitly refresh the user profile with the latest unique_name for both UAE Pass and regular users
  Future<void> _refreshUserProfile() async {
    final authService = Get.find<AuthService>();
    final secureStorage = authService.getSecureStorage();
    
    // Get token, which contains the unique_name value for all users
    final token = await secureStorage.read(key: 'auth_token');
    
    if (token != null && token.isNotEmpty) {
      try {
        // Parse JWT token to get unique_name
        final parts = token.split('.');
        if (parts.length >= 2) {
          // Decode the payload part of the JWT token
          String normalizedPayload = parts[1]
              .replaceAll('-', '+')
              .replaceAll('_', '/');
              
          // Add padding if needed
          while (normalizedPayload.length % 4 != 0) {
            normalizedPayload += '=';
          }
          
          final payloadBytes = base64Decode(normalizedPayload);
          final payloadMap = json.decode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
          
          // Extract unique_name from token payload
          final uniqueName = payloadMap['unique_name'] as String?;
          
          print('Refreshed unique_name from token: $uniqueName');
          
          if (uniqueName != null && uniqueName.isNotEmpty && _userProfile != null) {
            // Create updated profile with the unique_name
            final updatedProfile = UserProfile(
              id: _userProfile!.id,
              userName: _userProfile!.userName,
              name: _userProfile!.name,
              email: _userProfile!.email,
              phone: _userProfile!.phone,
              roles: _userProfile!.roles,
              isUaePassUser: _userProfile!.isUaePassUser,
              uniqueName: uniqueName,
            );
            
            // Update the state and save to auth service
            if (mounted) {
              setState(() {
                _userProfile = updatedProfile;
              });
              // Also save the updated profile to auth service for persistence
              await authService.saveUserProfile(updatedProfile);
            }
          }
        }
      } catch (e) {
        print('Error parsing token to get unique_name: $e');
      }
    }
    
    // Also check UAE Pass specific storage for unique_name (as a backup)
    final authMethod = await secureStorage.read(key: 'auth_method');
    if (authMethod == 'uae_pass') {
      final uaePassUniqueName = await secureStorage.read(key: 'uae_pass_unique_name');
      if (uaePassUniqueName != null && uaePassUniqueName.isNotEmpty && 
          _userProfile != null && (_userProfile!.uniqueName == null || _userProfile!.uniqueName!.isEmpty)) {
        final updatedProfile = UserProfile(
          id: _userProfile!.id,
          userName: _userProfile!.userName,
          name: _userProfile!.name,
          email: _userProfile!.email,
          phone: _userProfile!.phone,
          roles: _userProfile!.roles,
          isUaePassUser: true,
          uniqueName: uaePassUniqueName,
        );
        
        if (mounted) {
          setState(() {
            _userProfile = updatedProfile;
          });
          // Save updated profile
          await authService.saveUserProfile(updatedProfile);
        }
      }
    }
  }
  
  // Helper method to extract unique_name directly from JWT token
  Future<String?> _getUniqueNameDirectlyFromToken() async {
    try {
      // Get the auth service and secure storage
      final authService = Get.find<AuthService>();
      final secureStorage = authService.getSecureStorage();
      
      // Try to get token
      final token = await secureStorage.read(key: 'auth_token');
      
      if (token != null && token.isNotEmpty) {
        // Parse JWT token
        final parts = token.split('.');
        if (parts.length >= 2) {
          // Decode payload
          String normalizedPayload = parts[1]
            .replaceAll('-', '+')
            .replaceAll('_', '/');
          
          // Add padding if needed
          while (normalizedPayload.length % 4 != 0) {
            normalizedPayload += '=';
          }
          
          final payloadBytes = base64Decode(normalizedPayload);
          final payloadMap = json.decode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
          
          // Get unique_name claim
          final uniqueName = payloadMap['unique_name'] as String?;
          return uniqueName;
        }
      }
      
      // As a fallback, try to get from UAE Pass specific storage
      final authMethod = await secureStorage.read(key: 'auth_method');
      if (authMethod == 'uae_pass') {
        return await secureStorage.read(key: 'uae_pass_unique_name');
      }
    } catch (e) {
      print('Error getting unique name from token: $e');
    }
    return null;
  }
  
  void _getUserProfile() async {
    _userProfile = _authService.getUserProfile();
    
    // Check if this is a UAE Pass login and get the UAE Pass unique_name if available
    final authService = Get.find<AuthService>();
    final secureStorage = authService.getSecureStorage();
    final authMethod = await secureStorage.read(key: 'auth_method');
    
    if (authMethod == 'uae_pass') {
      // Read the unique_name directly from secure storage
      final uaePassUniqueName = await secureStorage.read(key: 'uae_pass_unique_name');
      
      if (uaePassUniqueName != null && uaePassUniqueName.isNotEmpty) {
        // Update the profile with the UAE Pass unique_name
        if (_userProfile != null) {
          setState(() {
            // Create a new profile with the UAE Pass unique_name
            _userProfile = UserProfile(
              id: _userProfile!.id,
              userName: _userProfile!.userName,
              name: _userProfile!.name,
              email: _userProfile!.email,
              phone: _userProfile!.phone,
              roles: _userProfile!.roles,
              isUaePassUser: true,
              uniqueName: uaePassUniqueName,
            );
          });
        }
      }
    }
    
    // Listen for changes to the user profile
    _authService.currentUser.listen((user) {
      setState(() {
        _userProfile = user;
      });
    });
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
    final AppLocalizations localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/adcda_logo.png',
          height: 36,
          width: 36,
        ),
        actions: [
          // Refresh button in header
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSurveys,
            tooltip: localizations.translate('retry'),
          ),
          // Language selector widget
          LanguageSelector(
            onLanguageChanged: _handleLanguageChanged,
          ),
        ],
      ),
      // Add drawer for side menu with user information
      drawer: _buildDrawer(context, localizations),
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
  
  // Build drawer with user information and logout button
  Widget _buildDrawer(BuildContext context, AppLocalizations localizations) {
    // Decode the userID from token when drawer is opened
    // This ensures we always get the most up-to-date information
    final Future<String?> userIdFuture = _getUniqueNameDirectlyFromToken();
    
    print('📋 Drawer: Refreshing user ID from token...');
    
    return Drawer(
      child: Column(
        children: [
          // User profile header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
            ),
            // Use a FutureBuilder to ensure we always get the latest decoded unique_name
            accountName: FutureBuilder<String?>(
              // Always use a fresh future when drawer is opened
              future: userIdFuture,
              builder: (context, snapshot) {
                // Default display name if we can't get it from token
                String displayName = '';
                
                // If we have data from the future, use that
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                  displayName = snapshot.data!;
                  print('📋 Drawer displaying decoded userID: $displayName');
                } 
                // Otherwise fall back to user profile data
                else if (_userProfile != null) { 
                  if (_userProfile!.uniqueName != null && _userProfile!.uniqueName!.isNotEmpty) {
                    displayName = _userProfile!.uniqueName ?? '';
                    print('📋 Drawer using profile uniqueName: $displayName');
                  } else if (_userProfile!.isUaePassUser) {
                    displayName = _userProfile!.userName ?? '';
                    print('📋 Drawer using profile userName: $displayName');
                  } else {
                    displayName = _userProfile!.name ?? '';
                    print('📋 Drawer using profile name: $displayName');
                  }
                }
                
                if (displayName.isEmpty) {
                  displayName = localizations.translate('user') ?? 'User';
                  print('📋 Drawer using default name: $displayName');
                }
                
                return Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                );
              },
            ),
            // Removed secondary label display
            accountEmail: null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              // Use ADCDA logo instead of user initial
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset(
                    'assets/images/adcda_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Home option as a list item
          ListTile(
            leading: Icon(Icons.home, color: AppColors.primaryColor),
            title: Text(
              localizations.translate('home'),
              style: const TextStyle(fontFamily: 'NotoKufiArabic', color: Colors.black),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          const Divider(),
          // Logout option as a list item
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              localizations.translate('logout'),
              style: const TextStyle(fontFamily: 'NotoKufiArabic', color: Colors.black),
            ),
            onTap: () async {
              // Show confirmation dialog
              final bool confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 16),
                      // Icon at the top
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      // Title after the icon
                      Text(
                        localizations.translate('logout'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      // Message
                      Text(
                        localizations.translate('logoutConfirmation'),
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      // Buttons in a row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Cancel button
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                localizations.translate('cancel'),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Logout button (red)
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red,
                                side: BorderSide(color: Colors.red, width: 1),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                localizations.translate('logout'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ) ?? false;
              
              if (confirm) {
                // Close drawer
                Navigator.pop(context);
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                
                // Logout
                await _authService.logout();
                
                // Close loading indicator
                Navigator.pop(context);
                
                // Navigate to login screen
                Get.offAll(() => const LoginScreen());
              }
            },
          ),
          const Spacer(),
          // App version at the bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0', // App version
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
