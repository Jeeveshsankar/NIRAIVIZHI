import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../generated/app_localizations.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Remove the problematic import and use a placeholder for localization
import 'dart:math';
final modelUrl = 'http://172.17.43.89:5000';

// Placeholder for localization since we can't generate the files
class S {
  static S of(BuildContext context) {
    return S();
  }

  String get healthSurveillanceSystem => "HEALTH SURVEILLANCE SYSTEM";
  String get selectYourLanguage => "Select Your Language";
  String get searchLanguage => "Search language...";
  String get noLanguagesFound => "No languages found";
  String get offlineMode => "Offline Mode";
  String get offlineModeDescription => "Use app without internet connection";
  String get continueText => "CONTINUE";
}

class AlertSystem {
  static Future<void> sendSMS(String message, String phoneNumber) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch SMS';
    }
  }

  static Future<void> sendWhatsApp(String message, String phoneNumber) async {
    // Remove any non-digit characters from phone number
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: formattedNumber,
      queryParameters: {'text': message},
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  static Future<void> makeCall(String phoneNumber) async {
    final Uri callUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      throw 'Could not make call';
    }
  }

  static Map<String, String> getAlertTemplates(String userType) {
    switch (userType) {
      case 'health_official':
        return {
          'outbreak_alert': 'URGENT: Disease outbreak detected. Dispatch medical teams immediately.',
          'resource_request': 'Need additional resources for outbreak response.',
          'preventive_measures': 'Initiate preventive measures in high-risk areas.'
        };
      case 'village_leader':
        return {
          'water_contamination': 'WARNING: Water source contaminated. Boil water before use.',
          'community_meeting': 'Emergency community meeting scheduled.',
          'health_alert': 'Health alert: Increased disease cases in village.'
        };
      case 'asha_worker':
        return {
          'symptom_report': 'Multiple cases of symptoms reported in area.',
          'water_test': 'Water test results show contamination.',
          'follow_up': 'Patient follow-up needed for suspected cases.'
        };
      default:
        return {
          'general': 'Important community health announcement.'
        };
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HealthSurveillanceApp());
}

class HealthSurveillanceApp extends StatefulWidget {
  const HealthSurveillanceApp({super.key});

  @override
  State<HealthSurveillanceApp> createState() => _HealthSurveillanceAppState();

  // Method to update locale from anywhere in the app
  static void setLocale(BuildContext context, Locale newLocale) {
    _HealthSurveillanceAppState? state = context.findAncestorStateOfType<_HealthSurveillanceAppState>();
    state?.setLocale(newLocale);
  }
}

class _HealthSurveillanceAppState extends State<HealthSurveillanceApp> {
  Locale _locale = const Locale('ta'); // Default to Tamil

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
    
    // Save the preference
    _saveLocalePreference(newLocale);
  }

  Future<void> _saveLocalePreference(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  Future<void> _loadLocalePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ta';
    setState(() {
      _locale = Locale(languageCode);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLocalePreference();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIRAIVIZHI - Health Surveillance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2A7FBA),
          primary: const Color(0xFF2A7FBA),
          secondary: const Color(0xFF4CAF50),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ta', ''),
        Locale('hi', ''),
        // Add other supported locales here
      ],
      locale: _locale,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _fadeController;
  late AnimationController _taglineController;

  late Animation<double> _drawAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();

    // "N" drawing animation
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOutCubic,
    );

    // Fade in NIRAIVIZHI text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Fade in Tagline
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _taglineAnimation = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    // Sequence animations
    _drawController.forward().whenComplete(() {
      _fadeController.forward().whenComplete(() {
        _taglineController.forward();
      });
    });

    // Navigate after splash (extended to 8 seconds total)
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LanguageSelectionScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _fadeController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F3F), Color(0xFF0074D9)], // deep navy → aqua
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated "N"
              AnimatedBuilder(
                animation: _drawAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: FancyNPainter(progress: _drawAnimation.value),
                    size: const Size(200, 200),
                  );
                },
              ),

              const SizedBox(height: 30),

              // NIRAIVIZHI
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  "NIRAIVIZHI",
                  style: GoogleFonts.montserrat(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.cyanAccent.withOpacity(0.9),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // HEALTH SURVEILLANCE SYSTEM (tagline)
              FadeTransition(
                opacity: _taglineAnimation,
                child: Text(
                  S.of(context).healthSurveillanceSystem, // Use localization
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter to draw glowing Aqua "N"
class FancyNPainter extends CustomPainter {
  final double progress; // expected 0.0 - 1.0
  FancyNPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      colors: [Colors.cyanAccent, Colors.blueAccent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final height = size.height;
    final width = size.width;

    // Stylish "N"
    path.moveTo(width * 0.15, height);
    path.lineTo(width * 0.15, height * 0.05);
    path.lineTo(width * 0.85, height);
    path.lineTo(width * 0.85, height * 0.05);

    final p = progress.clamp(0.0, 1.0);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    double totalLength = metrics.fold(0, (sum, m) => sum + m.length);

    double drawLength = totalLength * p;
    final drawnPath = Path();

    for (final metric in metrics) {
      if (drawLength <= 0) break;
      final take = math.min(metric.length, drawLength);
      drawnPath.addPath(metric.extractPath(0.0, take), Offset.zero);
      drawLength -= take;
    }

    canvas.drawPath(drawnPath, paint);
  }

  @override
  bool shouldRepaint(covariant FancyNPainter old) =>
      old.progress != progress;
}

// ---------------------- LANGUAGE SELECTION SCREEN ----------------------

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'Tamil'; // Default to Tamil
  bool _offlineMode = false;
  String _searchQuery = '';

  // Complete list of languages including Tamil
  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'}, // Added Tamil
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'as', 'name': 'Assamese', 'nativeName': 'অসমীয়া'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'mni', 'name': 'Manipuri/Meitei', 'nativeName': 'ꯃꯩꯇꯩꯂꯣꯟ'},
    {'code': 'kha', 'name': 'Khasi', 'nativeName': 'Khasi'},
    {'code': 'gar', 'name': 'Garo', 'nativeName': 'Garo'},
    {'code': 'lus', 'name': 'Mizo (Lushai)', 'nativeName': 'Mizo'},
    {'code': 'brx', 'name': 'Bodo', 'nativeName': 'बर\' / बड़ो'},
    {'code': 'ne', 'name': 'Nepali', 'nativeName': 'नेपाली'},
    {'code': 'aao', 'name': 'Ao Naga', 'nativeName': 'Ao Naga'},
    {'code': 'njm', 'name': 'Angami Naga', 'nativeName': 'Angami Naga'},
    {'code': 'nsm', 'name': 'Sumi Naga', 'nativeName': 'Sumi Naga'},
    {'code': 'nmf', 'name': 'Tangkhul', 'nativeName': 'Tangkhul'},
    {'code': 'mrg', 'name': 'Mishing', 'nativeName': 'Mishing'},
    {'code': 'trp', 'name': 'Kokborok (Tripuri)', 'nativeName': 'Kokborok'},
    {'code': 'mop', 'name': 'Monpa', 'nativeName': 'Monpa'},
    {'code': 'njz', 'name': 'Nyishi', 'nativeName': 'Nyishi'},
    {'code': 'adi', 'name': 'Adi', 'nativeName': 'Adi'},
    {'code': 'clk', 'name': 'Mishmi (Idu)', 'nativeName': 'Mishmi'},
    {'code': 'nnp', 'name': 'Wancho', 'nativeName': 'Wancho'},
    {'code': 'njb', 'name': 'Nocte', 'nativeName': 'Nocte'},
    {'code': 'nbe', 'name': 'Konyak', 'nativeName': 'Konyak'},
    {'code': 'kht', 'name': 'Khamti', 'nativeName': 'Khamti'},
    {'code': 'sgk', 'name': 'Sangtam Naga', 'nativeName': 'Sangtam Naga'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ta';
    
    final currentLanguage = languages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => {'name': 'Tamil', 'code': 'ta'},
    );
    
    setState(() {
      _selectedLanguage = currentLanguage['name']!;
    });
  }

  List<Map<String, String>> get filteredLanguages {
    if (_searchQuery.isEmpty) return languages;
    return languages.where((language) {
      return language['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          language['nativeName']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _setDefaultLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    // Update app locale
    HealthSurveillanceApp.setLocale(context, Locale(languageCode));
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${languageCode.toUpperCase()} set as default language'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Text(
                'NIRAIVIZHI',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                S.of(context).healthSurveillanceSystem, // Localized tagline
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                S.of(context).selectYourLanguage, // Localized title
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: S.of(context).searchLanguage,
                          hintStyle: GoogleFonts.poppins(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: GoogleFonts.poppins(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 15),

                    Expanded(
                      child: filteredLanguages.isEmpty
                          ? Center(
                              child: Text(
                                S.of(context).noLanguagesFound,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final language = filteredLanguages[index];
                                return Card(
                                  color: _selectedLanguage == language['name']
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.white.withOpacity(0.7),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: const Icon(Icons.language, color: Color(0xFF0D47A1)),
                                    title: Text(
                                      language['name']!,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0D47A1),
                                      ),
                                    ),
                                    subtitle: Text(
                                      language['nativeName']!,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0D47A1),
                                      ),
                                    ),
                                    trailing: _selectedLanguage == language['name']
                                        ? const Icon(Icons.check_circle, color: Color(0xFF0D47A1))
                                        : null,
                                    onTap: () {
                                      final selectedLanguageCode = language['code']!;
                                      final selectedLanguageName = language['name']!;
                                      
                                      setState(() {
                                        _selectedLanguage = selectedLanguageName;
                                      });
                                      
                                      _setDefaultLanguage(selectedLanguageCode);
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Card(
                color: Colors.white.withOpacity(0.7),
                child: SwitchListTile(
                  title: Text(
                    S.of(context).offlineMode,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  subtitle: Text(
                    S.of(context).offlineModeDescription,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  value: _offlineMode,
                  onChanged: (value) {
                    setState(() {
                      _offlineMode = value;
                    });
                  },
                  activeColor: Colors.black,
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const UserPortalScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    S.of(context).continueText,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserPortalScreen extends StatefulWidget {
  const UserPortalScreen({super.key});
  @override
  State<UserPortalScreen> createState() => _UserPortalScreenState();
}

class _UserPortalScreenState extends State<UserPortalScreen> {
  String _selectedPortal = '';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  final List<Map<String, dynamic>> portals = [
    {
      'label': 'ASHA',
      'icon': Icons.medical_services,
      'color': const Color(0xFF4CAF50),
      'lightColor': const Color(0xFFE8F5E9),
      'key': 'asha_worker'
    },
    {
      'label': 'Leader',
      'icon': Icons.groups,
      'color': const Color(0xFF607D8B),
      'lightColor': const Color(0xFFECEFF1),
      'key': 'village_leader'
    },
    {
      'label': 'Health',
      'icon': Icons.analytics,
      'color': const Color(0xFF2196F3),
      'lightColor': const Color(0xFFE3F2FD),
      'key': 'health_official'
    },
    {
      'label': 'Community',
      'icon': Icons.people,
      'color': const Color(0xFF9C27B0),
      'lightColor': const Color(0xFFF3E5F5),
      'key': 'community_member'
    },
    {
      'label': 'HYDROBOT',
      'icon': Icons.smart_toy,
      'color': const Color(0xFF00BCD4),
      'lightColor': const Color(0xFFE0F7FA),
      'key': 'hydrobot'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF87CEEB), // Sky Blue
              Color(0xFFB3E5FC), // Light Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // App Logo/Title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.health_and_safety, 
                         color: Color(0xFF1976D2), size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'NIRAIVIZHI',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1976D2),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Instruction text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select your portal to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Color(0xFF546E7A),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // Vertical portal list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: portals.length,
                  itemBuilder: (context, index) {
                    return _buildPortalCard(portals[index]);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(Map<String, dynamic> portal) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 90,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (portal['key'] == 'hydrobot') {
              _navigateToHydroBot(context);
            } else {
              setState(() {
                _selectedPortal = portal['key'];
                _errorMessage = '';
                _usernameController.clear();
                _passwordController.clear();
              });
              _showLoginDialog(portal);
            }
          },
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: portal['lightColor'],
                  shape: BoxShape.circle,
                ),
                child: Icon(portal['icon'], color: portal['color'], size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  portal['label'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: const Color(0xFF37474F),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.arrow_forward_ios,
                    color: Color(0xFFB0BEC5), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginDialog(Map<String, dynamic> portal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: _buildLoginForm(setDialogState, portal),
          ),
        ),
      ),
    ).then((_) {
      // Reset state when dialog is closed
      setState(() {
        _isLoading = false;
        _errorMessage = '';
      });
    });
  }

  Widget _buildLoginForm(StateSetter setDialogState, Map<String, dynamic> portal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: portal['lightColor'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(portal['icon'], color: portal['color'], size: 28),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Login to ${_getPortalName(_selectedPortal)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: const Color(0xFF37474F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _isLoading
              ? CircularProgressIndicator(color: portal['color'])
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: portal['color'],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _handleLogin(setDialogState, portal['key']),
                    child: Text(
                      "Login",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPortal = '';
                _usernameController.clear();
                _passwordController.clear();
                _errorMessage = '';
              });
            },
            child: const Text("Back to Portal Selection"),
          ),
        ],
      ),
    );
  }

  String _getPortalName(String portalKey) {
    switch (portalKey) {
      case 'asha_worker':
        return 'ASHA Worker';
      case 'village_leader':
        return 'Village Leader';
      case 'health_official':
        return 'Health Official';
      case 'community_member':
        return 'Community Member';
      default:
        return '';
    }
  }

  void _handleLogin(StateSetter setDialogState, String portalKey) async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setDialogState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setDialogState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userRole = userData['role'] as String?;
          if (userRole == portalKey) {
            // Close the dialog first
            Navigator.pop(context);
            // Then navigate to the appropriate dashboard
            _navigateToDashboard(portalKey);
          } else {
            await FirebaseAuth.instance.signOut();
            setDialogState(() {
              _errorMessage = 'Access denied for this portal';
              _isLoading = false;
            });
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setDialogState(() {
        _errorMessage = e.message ?? 'Login failed';
        _isLoading = false;
      });
    }
  }

  void _navigateToDashboard(String portalKey) {
    switch (portalKey) {
      case 'asha_worker':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ASHAWorkerDashboard()));
        break;
      case 'village_leader':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VillageLeaderDashboard()));
        break;
      case 'health_official':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HealthOfficialDashboard()));
        break;
      case 'community_member':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CommunityMemberDashboard()));
        break;
    }
  }

  void _navigateToHydroBot(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => OptimusXAppWrapper(),
    ),
  );
}

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
class OptimusXAppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OPTIMUS-X',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF0A0E21),
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(), // Start with LoginScreen directly
      debugShowCheckedModeBanner: false,
    );
  }
}

class ASHAWorkerDashboard extends StatefulWidget {
  const ASHAWorkerDashboard({super.key});

  @override
  State<ASHAWorkerDashboard> createState() => _ASHAWorkerDashboardState();
}

class _ASHAWorkerDashboardState extends State<ASHAWorkerDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final uid = FirebaseAuth.instance.currentUser?.uid;

    Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch all fields once
  }
// Add these variables at the top of your class
final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensor');
static const double tdsThreshold = 1000.0;
static const double turbidityThreshold = 50.0;
double tdsValue = 0.0;
double turbidity = 0.0;

Future<void> fetchUserData() async {
  try {
    print('🔄 Starting fetchUserData for UID: $uid');
    
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        userData = doc.data() as Map<String, dynamic>?;
        isLoading = false;
      });
      print('✅ User data fetched successfully');
      
      // After fetching user data, also check sensor data and send alerts if needed
    } else {
      print('❌ User document does not exist');
      setState(() {
        userData = {'error': 'User not found'};
        isLoading = false;
      });
    }

  } catch (e) {
    print('❌ Firestore fetch error: $e');
    setState(() {
      userData = {'error': 'Failed to fetch data: $e'};
      isLoading = false;
    });
  }
}


  // Mock data for ASHA Worker
  final List<Map<String, dynamic>> _myPatients = [
    {'name': 'Rahul Sharma', 'age': 32, 'village': 'Gandhi Nagar', 'lastVisit': '2 days ago', 'status': 'Needs Follow-up', 'symptoms': 'Fever, Diarrhea'},
    {'name': 'Sunita Devi', 'age': 28, 'village': 'Nehru Colony', 'lastVisit': '1 week ago', 'status': 'Stable', 'symptoms': 'Cough, Cold'},
    {'name': 'Amit Kumar', 'age': 45, 'village': 'Gandhi Nagar', 'lastVisit': '3 days ago', 'status': 'Recovering', 'symptoms': 'Stomach Pain'},
    {'name': 'Priya Singh', 'age': 22, 'village': 'Tagore Enclave', 'lastVisit': 'Today', 'status': 'New Case', 'symptoms': 'Fever, Headache'},
  ];

  final List<Map<String, dynamic>> _recentVisits = [
    {'date': 'Today', 'visits': 8, 'symptoms': ['Fever', 'Diarrhea']},
    {'date': 'Yesterday', 'visits': 12, 'symptoms': ['Vomiting', 'Dehydration']},
    {'date': '2 days ago', 'visits': 6, 'symptoms': ['Stomach Pain', 'Fever']},
  ];

  final List<Map<String, dynamic>> _waterTests = [
    {'source': 'Village Well', 'date': 'Today', 'status': 'Moderate Risk', 'bacteria': 15, 'ph': 6.8, 'turbidity': 25},
    {'source': 'River Point', 'date': 'Yesterday', 'status': 'High Risk', 'bacteria': 45, 'ph': 5.2, 'turbidity': 65},
    {'source': 'Hand Pump', 'date': '3 days ago', 'status': 'Low Risk', 'bacteria': 5, 'ph': 7.2, 'turbidity': 8},
  ];

  // For connecting to sensors
  bool _isWaterSensorConnected = false;
  bool _isHealthSensorConnected = false;
  double _currentPH = 7.0;
  double _currentTurbidity = 10.0;
  int _currentBacteria = 0;
  

  void _goBackToPortal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UserPortalScreen()),
    );
  }

  // Connect to water quality sensor
  Future<void> _connectToWaterSensor() async {
    setState(() {
      _isWaterSensorConnected = true;
    });
    
    // Simulate sensor data reading (replace with actual sensor API call)
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _currentPH = 6.8 + math.Random().nextDouble() * 1.0;
      _currentTurbidity = 5.0 + math.Random().nextDouble() * 40.0;
      _currentBacteria = math.Random().nextInt(50);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Water sensor connected successfully')),
    );
  }

  // Connect to health monitoring sensor
  Future<void> _connectToHealthSensor() async {
    setState(() {
      _isHealthSensorConnected = true;
    });
    
    // Simulate health sensor data (replace with actual API)
    await Future.delayed(const Duration(seconds: 2));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health monitoring sensor connected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToPortal,
        ),
        title: Text(
          'ASHA Worker Portal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showASHAAlertsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showProfileDialog();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9),
              Color(0xFFC8E6C9),
              Color(0xFFA5D6A7),
            ],
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildASHADashboard(),
            _buildPatientsTab(),
            _buildWaterTestingTab(),
            _buildReportsTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Patients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Water Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showASHAQuickActions();
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildASHADashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Community Health Overview',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildASHAStatusCards(),
            const SizedBox(height: 24),
            Text(
              'Recent Patient Visits',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentVisits(),
            const SizedBox(height: 24),
            Text(
              'Water Test Results',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildWaterTestResults(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            _buildASHAQuickActions(),
          ],
        ),
      ),
    );
  }

 Widget _buildASHAStatusCards() {
  Future<Map<String, dynamic>?> fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  return FutureBuilder<Map<String, dynamic>?>(
    future: fetchUserData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data == null) {
        return const Center(child: Text('No data found'));
      }

      final data = snapshot.data!;
      final patients = data['patients'] ?? [];
      final waterTests = data['water_test'] ?? [];
        DateTime now = DateTime.now();

      List<Map<String, dynamic>> todaysVisitors = [];

          for (var patient in patients) {
      if (patient['lastVisit'] != null) {
        Timestamp ts = patient['lastVisit'];
        DateTime visitDate = ts.toDate();

        // Compare only year, month, and day
        bool isToday = visitDate.year == now.year &&
                       visitDate.month == now.month &&
                       visitDate.day == now.day;

        if (isToday) {
          // Add patient info + user reference if needed
          todaysVisitors.add(
             patient
          );
        }
      }
      }

      return Center(
        child: Column(
          children: [
            // Existing status cards row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Patients',
                    '${patients.length}',
                    Icons.people,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Today\'s Visits',
                    '${todaysVisitors.length}',
                    Icons.medical_services,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusCard(
                    'Water Tests',
                    '${waterTests.length}',
                    Icons.water_drop,
                    const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            
            // Today's Visits button
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _showTodaysVisitsDialog(todaysVisitors);
              },
              icon: const Icon(Icons.today, color: Colors.white),
              label: const Text(
                'View Today\'s Visits',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildRecentVisits() {
  Future<Map<String, dynamic>?> fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  return FutureBuilder<Map<String, dynamic>?>(
    future: fetchUserData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data == null) {
        return const Center(child: Text('No data found'));
      }

      final userData = snapshot.data!;
      final List<dynamic> patients = userData['patients'] ?? [];

      DateTime now = DateTime.now();
      DateTime yesterday = now.subtract(const Duration(days: 1));
      DateTime twoDaysAgo = now.subtract(const Duration(days: 2));

      bool isSameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;

      List<dynamic> filterVisits(DateTime targetDate) {
        return patients.where((p) {
          final ts = p['lastVisit'];
          if (ts == null) return false;
          return isSameDay((ts as Timestamp).toDate(), targetDate);
        }).toList();
      }

      List<String> extractNames(List<dynamic> visits) {
        return visits.map((p) => p['name']?.toString() ?? 'Unnamed').toList();
      }

      final todayVisits = filterVisits(now);
      final yesterdayVisits = filterVisits(yesterday);
      final twoDaysAgoVisits = filterVisits(twoDaysAgo);

      final todayNames = extractNames(todayVisits);
      final yesterdayNames = extractNames(yesterdayVisits);
      final twoDaysAgoNames = extractNames(twoDaysAgoVisits);

      Widget buildVisitSection(String label, List<String> names, Color iconColor) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            names.isEmpty
                ? Text('No visitors', style: GoogleFonts.poppins(color: Colors.grey))
                : ListTile(
                    leading: Icon(Icons.medical_services, color: iconColor),
                    title: Text(
                      '${names.length} visited',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Names: ${names.join(', ')}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
            const SizedBox(height: 12),
          ],
        );
      }

      return Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🗓️ Recent Patient Visits',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildVisitSection('Today', todayNames, const Color(0xFF2196F3)),
                  buildVisitSection('Yesterday', yesterdayNames, const Color(0xFF4CAF50)),
                  buildVisitSection('2 Days Ago', twoDaysAgoNames, const Color(0xFF9C27B0)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


Widget _buildWaterTestResults() {
  return Center(
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var test in userData?['water_test'] ?? []) // Fixed: Added null check
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.water_drop, color: Color(0xFF2196F3)),
                  title: Text(
                    test['source'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${test['date']} - ${test['status']}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Chip(
                    label: Text(
                      '${test['bacteria']} CFU',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: test['status'] == 'High Risk'
                        ? Colors.red
                        : test['status'] == 'Moderate Risk'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildASHAQuickActions() {
  return Center(
    child: Column(
      children: [
        // Add Today's Visit button above the other action buttons
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            onPressed: () {
              _addTodaysVisit();
            },
            icon: const Icon(Icons.today, color: Colors.white),
            label: const Text(
              "Today's Visit",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Existing action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(Icons.person_add, 'New Patient', () {
              _showNewPatientDialog();
            }, const Color(0xFF4CAF50)),
            _buildActionButton(Icons.medical_services, 'Symptom Report', () {
              _showSymptomReportDialog();
            }, const Color(0xFF2196F3)),
            _buildActionButton(Icons.water_drop, 'Water Test', () {
              _navigateToHydroBot(context);
            }, const Color(0xFFFF9800)),
          ],
        ),
      ],
    ),
  );
}


void _navigateToHydroBot(BuildContext context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (context) => OptimusXAppWrapper(),
    ),
  );
}

// Add this method to handle today's visit functionality
void _addTodaysVisit() {
  final _formKey = GlobalKey<FormState>();
  String selectedPatient = '';
  String symptoms = '';
  String notes = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Record Today's Visit"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Patient'),
                  items: userData?['patients'].map<DropdownMenuItem<String>>((patient) {
                    return DropdownMenuItem<String>(
                      value: patient['name'],
                      child: Text(patient['name']),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Please select a patient' : null,
                  onChanged: (value) => selectedPatient = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Symptoms Observed'),
                  maxLines: 2,
                  onChanged: (value) => symptoms = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Update the patient's last visit to today
                setState(() {
                  for (var patient in userData!['patients']) {
                    if (patient['name'] == selectedPatient) {
                      patient['lastVisit'] = Timestamp.now();
                      // Add symptoms if provided
                      if (symptoms.isNotEmpty) {
                        if (patient['symptoms'] is String) {
                          patient['symptoms'] = [patient['symptoms'], symptoms];
                        } else if (patient['symptoms'] is List) {
                          patient['symptoms'].add(symptoms);
                        } else {
                          patient['symptoms'] = [symptoms];
                        }
                      }
                      break;
                    }
                  }
                });
                
                // Update in Firebase
                FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'patients': userData?['patients']});
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visit recorded successfully')),
                );
              }
            },
            child: const Text('Save Visit'),
          ),
        ],
      );
    },
  );
}

// ... (rest of the code remains the same)
  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

Widget _buildPatientsTab() {
  final patients = userData?['patients'] ?? [];
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Column(
        children: [
          Text(
            'My Patients',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          ...patients.map((patient) => Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF4CAF50),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                patient['name'] ?? 'Unknown Name',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${patient['age'] ?? 'Unknown'} years • ${patient['village'] ?? 'Unknown Village'}',
                style: GoogleFonts.poppins(),
              ),
              trailing: Chip(
                label: Text(
                  patient['status'] ?? 'Unknown Status',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: (patient['status'] == 'Needs Follow-up'
                    ? Colors.orange
                    : patient['status'] == 'New Case'
                    ? Colors.blue
                    : Colors.green),
              ),
              onTap: () {
                _showPatientDetails(patient);
              },
            ),
          )).toList(),
          if (patients.isEmpty)
            const Text('No patients available'),
        ],
      ),
    ),
  );
}
  Widget _buildWaterTestingTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: Column(
        children: [
          Text(
            'Water Quality Testing',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.water_drop, size: 50, color: Color(0xFF2196F3)),
                  const SizedBox(height: 16),
                  Text(
                    'Test Water Quality',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use HydroBot to check water sources for contamination',
                    style: GoogleFonts.poppins(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // HydroBot connection status - RESPONSIVE VERSION
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // For smaller screens, stack vertically
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            Column(
                              children: [
                                Icon(
                                  _isWaterSensorConnected ? Icons.sensors : Icons.sensors_off,
                                  color: _isWaterSensorConnected ? Colors.green : Colors.red,
                                  size: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isWaterSensorConnected ? 'HydroBot Connected' : 'HydroBot Offline',
                                  style: TextStyle(
                                    color: _isWaterSensorConnected ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _connectToWaterSensor,
                                icon: const Icon(Icons.connect_without_contact, size: 18),
                                label: Text(_isWaterSensorConnected ? 'Reconnect HydroBot' : 'Connect HydroBot'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      } 
                      // For larger screens, use row layout
                      else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  _isWaterSensorConnected ? Icons.sensors : Icons.sensors_off,
                                  color: _isWaterSensorConnected ? Colors.green : Colors.red,
                                  size: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isWaterSensorConnected ? 'HydroBot Connected' : 'HydroBot Offline',
                                  style: TextStyle(
                                    color: _isWaterSensorConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _connectToWaterSensor,
                              icon: const Icon(Icons.connect_without_contact),
                              label: Text(_isWaterSensorConnected ? 'Reconnect HydroBot' : 'Connect HydroBot'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Display current HydroBot sensor readings if connected
                  if (_isWaterSensorConnected) ...[
                    const Divider(),
                    const Text(
                      'HydroBot Current Sensor Readings:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    
                    // Sensor readings in a responsive grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            _buildSensorCard('pH', '${_currentPH.toStringAsFixed(1)}', 
                                _currentPH < 6.5 || _currentPH > 8.5 ? Colors.red : Colors.green,
                                Icons.science),
                            _buildSensorCard('Turbidity', '${_currentTurbidity.toStringAsFixed(0)} NTU', 
                                _currentTurbidity > 40 ? Colors.orange : Colors.green,
                                Icons.opacity),
                            _buildSensorCard('Bacteria', '$_currentBacteria CFU', 
                                _currentBacteria > 20 ? Colors.red : Colors.green,
                                Icons.biotech),
                            _buildSensorCard('TDS', '${(_currentTurbidity * 2.5).toStringAsFixed(0)} ppm', 
                                (_currentTurbidity * 2.5) > 500 ? Colors.orange : Colors.green,
                                Icons.water),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Download PDF button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _downloadWaterTestReport();
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showWaterTestForm();
                      },
                      icon: const Icon(Icons.science),
                      label: const Text('Record Water Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Water Tests',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
...(userData?['water_test'] ?? []).map((test) => Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  margin: const EdgeInsets.only(bottom: 16),
  child: ListTile(
    leading: const Icon(Icons.water_drop, color: Color(0xFF2196F3)),
    title: Text(
      test['source'] ?? 'Unknown Source',
      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
    ),
    subtitle: Text(
      'Tested on ${test['date'] ?? 'Unknown Date'}',
      style: GoogleFonts.poppins(),
    ),
    trailing: Chip(
      label: Text(
        test['status'] ?? 'Unknown Status',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: (test['status'] == 'High Risk'
          ? Colors.red
          : test['status'] == 'Moderate Risk'
          ? Colors.orange
          : Colors.green),
    ),
  ),
)).toList(),
if ((userData?['water_test'] ?? []).isEmpty)
  const Text('No water tests available'),

        ],
      ),
    ),
  );
}
Widget _buildSensorCard(String parameter, String value, Color color, IconData icon) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                parameter,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showTodaysVisitsDialog(List<Map<String, dynamic>> todaysVisits) {
  // Filter patients with visits today
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Today's Patient Visits"),
        content: SizedBox(
          width: double.maxFinite,
          child: todaysVisits.isEmpty
              ? const Text('No visits recorded for today')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: todaysVisits.length,
                  itemBuilder: (context, index) {
                    final patient = todaysVisits[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF2196F3),
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                        title: Text(patient['name']),
                        subtitle: Text(
                          '${patient['age']} years • ${patient['village']}',
                        ),
                        trailing: Chip(
                          label: Text(
                            patient['status'],
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor: patient['status'] == 'Needs Follow-up'
                              ? Colors.orange
                              : patient['status'] == 'New Case'
                                  ? Colors.blue
                                  : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
    }

void _downloadWaterTestReport() async {
  // This would generate and download a PDF report in a real app
  // For now, show a success message
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Water test report downloaded as PDF'),
      duration: Duration(seconds: 2),
    ),
  );
  
  // In a real implementation, you would use a PDF generation package
  // like pdf: ^3.10.0 to create a detailed report
  print('Generating PDF report with current sensor data...');
  print('pH: $_currentPH, Turbidity: $_currentTurbidity, Bacteria: $_currentBacteria');
}
  Widget _buildSensorReading(String parameter, String value, Color color) {
    return Column(
      children: [
        Text(
          parameter,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Reports & Analytics',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.analytics, size: 50, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    Text(
                      'Weekly Health Report',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Summary of symptoms and cases in your assigned area',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _generateWeeklyReport();
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Generate Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up, size: 50, color: Color(0xFF2196F3)),
                    const SizedBox(height: 16),
                    Text(
                      'Symptom Trends',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track symptom patterns over time',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Health sensor connection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(
                              _isHealthSensorConnected ? Icons.monitor_heart : Icons.heart_broken,
                              color: _isHealthSensorConnected ? Colors.green : Colors.red,
                              size: 30,
                            ),
                            Text(
                              _isHealthSensorConnected ? 'Health Monitor On' : 'Monitor Offline',
                              style: TextStyle(
                                color: _isHealthSensorConnected ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _connectToHealthSensor,
                          icon: const Icon(Icons.monitor_heart),
                          label: Text(_isHealthSensorConnected ? 'Refresh Data' : 'Connect Monitor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _viewSymptomTrends();
                      },
                      icon: const Icon(Icons.show_chart),
                      label: const Text('View Trends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Alert sending section
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, size: 50, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Emergency Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send alerts to health officials and community',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _sendAlert();
                      },
                      icon: const Icon(Icons.notification_important),
                      label: const Text('Send Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showASHAAlertsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('ASHA Worker Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: userData?['alerts']?.length ?? 0,
            itemBuilder: (context, index) {
              final alert = userData?['alerts']?[index];
              if (alert == null) return const SizedBox();
              
              // Handle Firebase Timestamp conversion
              DateTime date;
              if (alert['date'] is Timestamp) {
                date = (alert['date'] as Timestamp).toDate();
              } else if (alert['date'] is int) {
                date = DateTime.fromMillisecondsSinceEpoch(alert['date']);
              } else {
                date = DateTime.now(); // fallback
              }
              
              final timeAgo = _getTimeAgo(date);
              
              return Column(
                children: [
                  ListTile(
                    leading: _getAlertIcon(alert['alert'] ?? ''),
                    title: Text(alert['alert'] ?? 'No alert message'),
                    subtitle: Text(timeAgo),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () async {
                        await _deleteAlert(index);
                        Navigator.of(context).pop();
                        // Only reopen if there are still alerts
                        if (userData?['alerts']?.isNotEmpty ?? false) {
                          _showASHAAlertsDialog();
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleAlertTap(alert);
                    },
                  ),
                  if (index < (userData?['alerts']?.length ?? 0) - 1) 
                    const Divider(),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close All'),
          ),
        ],
      );
    },
  );
}

// Function to delete alert from both local state and database
Future<void> _deleteAlert(int index) async {
  try {
    // Get the alert before removing it (for database reference)
    final alertToRemove = userData?['alerts']?[index];
    
    // Remove from local state first
    setState(() {
      userData?['alerts']?.removeAt(index);
    });
    
    // Update in Firebase database
    // Replace 'users' with your actual collection name and 'userId' with the actual user ID
    final userId = userData?['uid'] ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'alerts': FieldValue.arrayRemove([alertToRemove])
          });
    }
    
    print('Alert deleted successfully');
  } catch (e) {
    print('Error deleting alert: $e');
    // Optional: Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete alert: $e')),
    );
  }
}
// Helper function to get time ago string
String _getTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
  if (difference.inDays < 1) return '${difference.inHours} hours ago';
  if (difference.inDays < 7) return '${difference.inDays} days ago';
  if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
  return '${(difference.inDays / 30).floor()} months ago';
}

// Helper function to get appropriate icon based on alert type
Icon _getAlertIcon(String alert) {
  if (alert.toLowerCase().contains('diarrhea') || 
      alert.toLowerCase().contains('warning')) {
    return const Icon(Icons.warning, color: Colors.orange);
  } else if (alert.toLowerCase().contains('training') || 
             alert.toLowerCase().contains('session')) {
    return const Icon(Icons.info, color: Colors.blue);
  } else if (alert.toLowerCase().contains('medical') || 
             alert.toLowerCase().contains('supplies')) {
    return const Icon(Icons.medical_services, color: Colors.green);
  } else {
    return const Icon(Icons.notifications, color: Colors.grey);
  }
}


// Function to handle alert tap
void _handleAlertTap(Map<String, dynamic> alert) {
  // Handle specific alert actions based on alert content
  print('Alert tapped: ${alert['alert']} from ${alert['from']}');
  
  // You can add specific logic here based on alert type
  if (alert['alert'].toString().toLowerCase().contains('diarrhea')) {
    // Navigate to diarrhea cases screen
  } else if (alert['alert'].toString().toLowerCase().contains('training')) {
    // Navigate to training session screen
  }
  // Add more conditions as needed
}


  void _showASHAQuickActions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quick Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text('Register New Patient'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showNewPatientDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.green),
                title: const Text('Record Symptoms'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSymptomReportDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: const Text('Test Water Quality'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showWaterTestDialog();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: const Text('Send Alert'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendAlert();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showNewPatientDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String age = '';
    String village = '';
    String symptoms = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register New Patient'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter age' : null,
                    onSaved: (v) => age = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Village'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter village' : null,
                    onSaved: (v) => village = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Initial Symptoms'),
                    maxLines: 2,
                    onSaved: (v) => symptoms = v!.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() {
                    userData?['patients'].add({
                      'name': name,
                      'age': age,
                      'village': village,
                      'lastVisit': Timestamp.now(),
                      'status': 'New Case',
                      'symptoms': [symptoms]
                    });
                  });
                  FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'patients':userData?['patients']});
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Patient registered successfully')),
                  );
                }
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }


void _showSymptomReportDialog() {
  final _formKey = GlobalKey<FormState>();
  String apiUrl = modelUrl;  
  showDialog(
    context: context,
    builder: (context) {
      String? selectedPatient;
      String severity = 'Mild';
      DateTime onsetDate = DateTime.now();
      String prediction = 'Select symptoms to analyze';
      bool isLoading = false;

      // Full list of symptoms (add all 100+ symptoms here)
      List<String> allSymptoms = ["abnormal appearing skin", "abnormal appearing tongue", "abnormal breathing sounds", "abnormal involuntary movements", "abnormal movement of eyelid", "abnormal size or shape of ear", "absence of menstruation", "abusing alcohol", "acne or pimples", "ache all over", "allergic reaction", "antisocial behavior", "anxiety and nervousness", "apnea", "arm cramps or spasms", "arm lump or mass", "arm pain", "arm stiffness or tightness", "arm swelling", "arm weakness", "back cramps or spasms", "back mass or lump", "back pain", "back stiffness or tightness", "back swelling", "back weakness", "bedwetting", "bleeding from ear", "bleeding from eye", "bleeding gums", "bleeding in mouth", "bleeding or discharge from nipple", "blindness", "blood clots during menstrual periods", "blood in stool", "blood in urine", "bones are painful", "bowlegged or knock-kneed", "breathing fast", "burning abdominal pain", "burning chest pain", "cough", "coughing up sputum", "cross-eyed", "changes in stool appearance", "chest tightness", "chills", "cloudy eye", "congestion in chest", "constipation", "coryza", "cramps and spasms", "decreased appetite", "decreased heart rate", "delusions or hallucinations", "depression", "depressive or psychotic symptoms", "diaper rash", "diarrhea", "difficulty breathing", "difficulty eating", "difficulty in swallowing", "difficulty speaking", "diminished hearing", "diminished vision", "discharge in stools", "disturbance of memory", "disturbance of smell or taste", "double vision", "drainage in throat", "drug abuse", "dry lips", "dry or flaky scalp", "dizziness", "ear pain", "early or late onset of menopause", "elbow cramps or spasms", "elbow lump or mass", "elbow pain", "elbow stiffness or tightness", "elbow swelling", "elbow weakness", "emotional symptoms", "excessive anger", "excessive appetite", "excessive growth", "excessive urination at night", "eye burns or stings", "eye deviation", "eye moves abnormally", "eye pain", "eye redness", "eyelid lesion or rash", "eyelid retracted", "eyelid swelling", "facial pain", "fainting", "fatigue", "fears and phobias", "feeling cold", "feeling hot", "feeling hot and cold", "feeling ill", "fever", "flatulence", "fluid in ear", "fluid retention", "flu-like syndrome", "focal weakness", "foot or toe cramps or spasms", "foot or toe lump or mass", "foot or toe pain", "foot or toe stiffness or tightness", "foot or toe swelling", "foot or toe weakness", "foreign body sensation in eye", "frequent menstruation", "frequent urination", "frontal headache", "flushing", "gum pain", "hand or finger cramps or spasms", "hand or finger lump or mass", "hand or finger pain", "hand or finger stiffness or tightness", "hand or finger swelling", "hand or finger weakness", "headache", "heartburn", "heavy menstrual flow", "hemoptysis", "hesitancy", "hip lump or mass", "hip pain", "hip stiffness or tightness", "hip swelling", "hip weakness", "hoarse voice", "hostile behavior", "hot flashes", "hurts to breath", "hysterical behavior", "impotence", "incontinence of stool", "increased heart rate", "infertility", "infant feeding problem", "infant spitting up", "infrequent menstruation", "insomnia", "intermenstrual bleeding", "involuntary urination", "irregular appearing nails", "irregular appearing scalp", "irregular belly button", "irregular heartbeat", "irritable infant", "itching of scrotum", "itching of skin", "itching of the anus", "itchiness of eye", "itchy ear(s)", "itchy eyelid", "itchy scalp", "jaw pain", "jaw swelling", "jaundice", "joint pain", "joint stiffness or tightness", "joint swelling", "kidney mass", "knee cramps or spasms", "knee lump or mass", "knee pain", "knee stiffness or tightness", "knee swelling", "knee weakness", "lacrimation", "lack of growth", "leg cramps or spasms", "leg lump or mass", "leg pain", "leg stiffness or tightness", "leg swelling", "leg weakness", "lip sore", "lip swelling", "long menstrual periods", "loss of sensation", "loss of sex drive", "lump in throat", "lump over jaw", "lump or mass of breast", "low back cramps or spasms", "low back pain", "low back stiffness or tightness", "low back swelling", "low back weakness", "low self-esteem", "low urine output", "lymphedema", "mass in scrotum", "mass on ear", "mass on eyelid", "mass on vulva", "mass or swelling around the anus", "melena", "mouth dryness", "mouth pain", "mouth ulcer", "muscle cramps, contractures, or spasms", "muscle pain", "muscle stiffness or tightness", "muscle swelling", "muscle weakness", "nailbiting", "nasal congestion", "neck cramps or spasms", "neck mass", "neck pain", "neck stiffness or tightness", "neck swelling", "neck weakness", "nightmares", "nose deformity", "nosebleed", "nausea", "obsessions and compulsions", "pain during intercourse", "pain during pregnancy", "pain in eye", "pain in gums", "pain in testicles", "pain of the anus", "pain or soreness of breast", "pain during menstruation", "painful sinuses", "painful urination", "pallor", "palpitations", "paresthesia", "pelvic pain", "pelvic pressure", "penile discharge", "penis pain", "penis redness", "peripheral edema", "plugged feeling in ear", "polyuria", "poor circulation", "postpartum problems of the breast", "posture problems", "premature ejaculation", "premenstrual tension or irritability", "problems during pregnancy", "problems with movement", "problems with orgasm", "problems with shape or size of breast", "pulling at ears", "pupils unequal", "pus draining from ear", "pus in sputum", "pus in urine", "pus in sputum", "rectal bleeding", "redness in ear", "redness in or around nose", "regurgitation", "regurgitation.1", "recent pregnancy", "recent weight loss", "restlessness", "retention of urine", "rib pain", "ringing in ear", "scanty menstrual flow", "seizures", "sharp abdominal pain", "sharp chest pain", "shortness of breath", "shoulder cramps or spasms", "shoulder lump or mass", "shoulder pain", "shoulder stiffness or tightness", "shoulder swelling", "shoulder weakness", "side pain", "sinus congestion", "skin dryness, peeling, scaliness, or roughness", "skin growth", "skin irritation", "skin lesion", "skin moles", "skin oiliness", "skin on arm or hand looks infected", "skin on head or neck looks infected", "skin on leg or foot looks infected", "skin pain", "skin rash", "skin swelling", "sleepiness", "sleepwalking", "slurring words", "smoking problems", "sneezing", "sore in nose", "sore throat", "spots or clouds in vision", "spotting or bleeding during pregnancy", "stiffness all over", "stomach bloating", "stuttering or stammering", "suprapubic pain", "swelling of scrotum", "swollen abdomen", "swollen eye", "swollen lymph nodes", "swollen or red tonsils", "swollen tongue", "sweating", "symptoms of bladder", "symptoms of eye", "symptoms of face", "symptoms of infants", "symptoms of kidneys", "symptoms of prostate", "symptoms of the scrotum and testes", "temper problems", "thirst", "throat feels tight", "throat irritation", "throat redness", "throat swelling", "tongue bleeding", "tongue lesions", "tongue pain", "toothache", "too little hair", "unpredictable menstruation", "unusual color or odor to urine", "underweight", "upper abdominal pain", "unwanted hair", "uterine contractions", "vaginal bleeding after menopause", "vaginal discharge", "vaginal dryness", "vaginal itching", "vaginal pain", "vaginal redness", "vomiting", "vomiting blood", "vulvar irritation", "vulvar sore", "warts", "weakness", "weight gain", "wheezing", "white discharge from eye", "wrist cramps or spasms", "wrist lump or mass", "wrist pain", "wrist stiffness or tightness", "wrist swelling", "wrist weakness", "wrinkles on skin"];

      Map<String, bool> selectedSymptoms = { for (var s in allSymptoms) s: false };
      List<String> filteredSymptoms = List.from(allSymptoms);
      TextEditingController searchController = TextEditingController();

      return StatefulBuilder(
        builder: (context, setState) {

          // Filter symptoms on search
          void _filterSymptoms() {
            String query = searchController.text.toLowerCase();
            setState(() {
              filteredSymptoms = allSymptoms
                  .where((symptom) => symptom.toLowerCase().contains(query))
                  .toList();
            });
          }

          searchController.addListener(_filterSymptoms);

          // API call
          Future<void> predictDiseaseAPI() async {
            List<String> chosenSymptoms = selectedSymptoms.entries
                .where((entry) => entry.value)
                .map((entry) => entry.key)
                .toList();

            if (chosenSymptoms.length < 3) {
              setState(() => prediction = 'Select at least 3 symptoms to analyze');
              return;
            }

            setState(() => isLoading = true);

            try {
              final url = Uri.parse('$apiUrl/predict');
              Map<String, dynamic> apiData = {};
              selectedSymptoms.forEach((key, value) { apiData[key] = value; });

              final response = await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: json.encode(apiData),
              );

              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                if (data['success'] == true) {
                  setState(() => prediction = data['prediction']);
                } else {
                  setState(() => prediction = 'Prediction error: ${data['error']}');
                }
              } else {
                setState(() => prediction = 'Server error: ${response.statusCode}');
              }
            } catch (e) {
              setState(() => prediction = 'Connection error: $e');
            } finally {
              setState(() => isLoading = false);
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Record Symptoms',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Patient dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Patient',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: selectedPatient,
                      items: (userData?['patients'] as List<dynamic>?)
                          ?.map<DropdownMenuItem<String>>((patient) {
                        return DropdownMenuItem<String>(
                          value: patient['name']?.toString() ?? '',
                          child: Text(patient['name']?.toString() ?? 'Unknown'),
                        );
                      }).toList() ?? [],
                      onChanged: (value) => setState(() => selectedPatient = value),
                      validator: (value) => value == null ? 'Please select a patient' : null,
                    ),
                    const SizedBox(height: 20),

                    // Search bar
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search symptoms...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Symptom selection list
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Column(
                            children: filteredSymptoms.map((symptom) {
                              return CheckboxListTile(
                                title: Text(symptom),
                                value: selectedSymptoms[symptom],
                                onChanged: (bool? value) {
                                  setState(() {
                                    selectedSymptoms[symptom] = value!;
                                  });
                                  // Call API only if at least 3 symptoms selected
                                  if (selectedSymptoms.values.where((v) => v).length >= 3) {
                                    predictDiseaseAPI();
                                  } else {
                                    setState(() => prediction = 'Select at least 3 symptoms to analyze');
                                  }
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Prediction display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Predicted Condition:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          isLoading
                              ? Row(
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Analyzing symptoms...',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  prediction,
                                  style: TextStyle(
                                    color: _getPredictionColor(prediction),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Severity and onset date row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Severity',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            value: severity,
                            items: const ['Mild', 'Moderate', 'Severe']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => severity = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: onsetDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && picked != onsetDate) {
                                setState(() => onsetDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${onsetDate.day}/${onsetDate.month}/${onsetDate.year}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Save & Cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();

                              List<String> chosenSymptoms = selectedSymptoms.entries
                                  .where((entry) => entry.value)
                                  .map((entry) => entry.key)
                                  .toList();

                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Symptoms recorded successfully. Prediction: $prediction'),
                                ),
                              );

                              // Save recent visit
                              if (mounted) {
                                setState(() {
                                  _recentVisits.insert(0, {
                                    'date': 'Today',
                                    'visits': 1,
                                    'symptoms': chosenSymptoms,
                                    'prediction': prediction,
                                    'severity': severity,
                                    'onsetDate': onsetDate.toString(),
                                  });
                                });
                              }
                            }
                          },
                          child: const Text('Save', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Helper function to get color based on prediction
Color _getPredictionColor(String prediction) {
  if (prediction.contains('Cholera') || prediction.contains('Severe')) {
    return Colors.red;
  } else if (prediction.contains('error') || prediction.contains('fail')) {
    return Colors.orange;
  } else {
    return Colors.blue[700]!;
  }
}

  void _showWaterTestDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Test Water Quality'),
          content: const Text('Water testing functionality would be implemented here.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _sendAlert() {
    String alertType = 'water_contamination';
    String message = '';
    String recipient = 'health_official';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Alert Type'),
                  value: alertType,
                  items: const [
                    DropdownMenuItem(value: 'water_contamination', child: Text('Water Contamination')),
                    DropdownMenuItem(value: 'disease_outbreak', child: Text('Disease Outbreak')),
                    DropdownMenuItem(value: 'resource_need', child: Text('Resource Need')),
                  ],
                  onChanged: (value) => alertType = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                  onChanged: (value) => message = value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Send To'),
                  value: recipient,
                  items: const [
                    DropdownMenuItem(value: 'health_official', child: Text('Health Official')),
                    DropdownMenuItem(value: 'village_leader', child: Text('Village Leader')),
                    DropdownMenuItem(value: 'community', child: Text('Community')),
                  ],
                  onChanged: (value) => recipient = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert sent successfully')),
                );
                
                // In a real app, this would call the AlertSystem
                print('Alert sent: $alertType to $recipient - $message');
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ASHA Worker Profile'),
          content:  Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text(data?['name']),
              ),
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text(data?['area']),
              ),
              ListTile(
                leading: Icon(Icons.phone),
                title: Text(data?['phone']),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Patient Details: ${patient['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: Text('Age: ${patient['age']} years'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text('Village: ${patient['village']}'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Last Visit: ${patient['lastVisit'].toDate()}'),
              ),
              ListTile(
                leading: const Icon(Icons.medical_services),
                title: Text('Status: ${patient['status']}'),
              ),
              if (patient['symptoms'] != null) 
                ListTile(
                  leading: const Icon(Icons.warning),
                  title: Text('Symptoms: ${patient['symptoms']}'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showWaterTestForm() {
    final _formKey = GlobalKey<FormState>();
    String waterSource = _waterTests.isNotEmpty ? _waterTests[0]['source'] : '';
    double phValue = 7.0;
    double turbidity = 10.0;
    int bacteriaCount = 0;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Water Test'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Water Source'),
                    value: waterSource,
                    items: _waterTests.map((test) {
                      return DropdownMenuItem<String>(
                        value: test['source'],
                        child: Text(test['source']),
                      );
                    }).toList(),
                    onChanged: (value) => waterSource = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'pH Level'),
                    keyboardType: TextInputType.number,
                    initialValue: phValue.toString(),
                    onChanged: (value) => phValue = double.tryParse(value) ?? 7.0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Turbidity (NTU)'),
                    keyboardType: TextInputType.number,
                    initialValue: turbidity.toString(),
                    onChanged: (value) => turbidity = double.tryParse(value) ?? 10.0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Bacteria Count (CFU)'),
                    keyboardType: TextInputType.number,
                    initialValue: bacteriaCount.toString(),
                    onChanged: (value) => bacteriaCount = int.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                    onChanged: (value) => notes = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Determine status based on values
                String status = 'Low Risk';
                if (bacteriaCount > 30 || phValue < 6.0 || phValue > 8.5 || turbidity > 50) {
                  status = 'High Risk';
                } else if (bacteriaCount > 10 || phValue < 6.5 || phValue > 8.0 || turbidity > 20) {
                  status = 'Moderate Risk';
                }

                setState(() {
                  _waterTests.insert(0, {
                    'source': waterSource,
                    'date': 'Today',
                    'status': status,
                    'bacteria': bacteriaCount,
                    'ph': phValue,
                    'turbidity': turbidity
                  });
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Water test recorded successfully')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _generateWeeklyReport() {
    // Generate a simple report
    int totalPatients = userData!['patients'].length;
    int newCases = userData!['patients'].where((p) => p['status'] == 'New Case').length;
    int followUpNeeded = _myPatients.where((p) => p['status'] == 'Needs Follow-up').length;
    
    int highRiskWaterSources = _waterTests.where((w) => w['status'] == 'High Risk').length;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Weekly Report Generated'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Health Surveillance Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text('Total Patients: $totalPatients'),
                Text('New Cases This Week: $newCases'),
                Text('Patients Needing Follow-up: $followUpNeeded'),
                const SizedBox(height: 8),
                Text('High Risk Water Sources: $highRiskWaterSources'),
                const SizedBox(height: 16),
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (highRiskWaterSources > 0)
                  const Text('- Conduct emergency water purification'),
                if (newCases > 5)
                  const Text('- Schedule community health awareness session'),
                if (followUpNeeded > 3)
                  const Text('- Prioritize patient follow-up visits'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // In a real app, this would export the report
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report exported successfully')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }

  void _viewSymptomTrends() {
    // Simulate symptom trends data
    Map<String, int> symptomCounts = {};
    for (var patient in _myPatients) {
      if (patient['symptoms'] != null) {
        List<String> symptoms = patient['symptoms'].toString().split(',');
        for (var symptom in symptoms) {
          symptom = symptom.trim();
          symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
        }
      }
    }
    
    // Sort symptoms by frequency
    var sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Symptom Trends'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Most Common Symptoms',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...sortedSymptoms.take(5).map((entry) {
                  return ListTile(
                    title: Text(entry.key),
                    trailing: Text('${entry.value} cases'),
                  );
                }).toList(),
                if (sortedSymptoms.isEmpty)
                  const Text('No symptom data available'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Portal')),
      body: const Center(child: Text('User Portal Screen')),
    );
  }


class VillageLeaderDashboard extends StatefulWidget {
  const VillageLeaderDashboard({super.key});

  @override
  State<VillageLeaderDashboard> createState() => _VillageLeaderDashboardState();
}

class _VillageLeaderDashboardState extends State<VillageLeaderDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Fetch all fields once
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      setState(() {
        userData = doc.data() as Map<String, dynamic>?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userData = {'error': 'Failed to fetch data'};
        isLoading = false;
      });
      print('Firestore fetch error: $e');
    }
  }

  // Mock data for Village Leader
  final Map<String, dynamic> _villageStats = {
    'population': 1245,
    'households': 285,
    'waterSources': 6,
    'healthWorkers': 3,
  };

  final List<Map<String, dynamic>> _villageAlerts = [
    {'type': 'Water', 'message': 'Well water contamination in Sector B', 'priority': 'High', 'date': '2 hours ago'},
    {'type': 'Health', 'message': 'Increased fever cases in East area', 'priority': 'Medium', 'date': '1 day ago'},
    {'type': 'Infrastructure', 'message': 'Water pump repair needed in Sector C', 'priority': 'Medium', 'date': '2 days ago'},
  ];

  final List<Map<String, dynamic>> _waterSources = [
    {'name': 'Village Well', 'status': 'Contaminated', 'lastTest': 'Today', 'risk': 'High'},
    {'name': 'River Point', 'status': 'Safe', 'lastTest': '2 days ago', 'risk': 'Low'},
    {'name': 'Hand Pump 1', 'status': 'Safe', 'lastTest': '3 days ago', 'risk': 'Low'},
    {'name': 'Hand Pump 2', 'status': 'Moderate', 'lastTest': '1 week ago', 'risk': 'Medium'},
  ];

  // Function to go back to portal selection
  void _goBackToPortal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UserPortalScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NIRAIVIZHI - VILLAGE LEADER DASHBOARD',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showVillageAlertsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              _showVillageMap();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToPortal,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1),
              Color(0xFFFFECB3),
              Color(0xFFFFE082),
            ],
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildVillageDashboard(),
            _buildWaterManagementTab(),
            _buildAlertsTab(),
            _buildCommunityTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF9800),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Water',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showVillageQuickActions();
        },
        backgroundColor: const Color(0xFFFF9800),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVillageDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Village Overview',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          _buildVillageStats(),
          const SizedBox(height: 24),
          Text(
            'Active Alerts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          _buildActiveAlerts(),
          const SizedBox(height: 24),
          Text(
            'Water Source Status',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          _buildWaterSourceStatus(),
          const SizedBox(height: 24),
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          _buildVillageQuickActions(),
        ],
      ),
    );
  }
Future<Map<String, dynamic>> _fetchVillageStats() async {
  try {
    // Fetch ASHA workers count
    final ashaWorkersQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('village', isEqualTo: userData?['villageName'] ?? '')
        .where('role', isEqualTo: 'asha_worker')
        .get();
    
    final ashaWorkersCount = ashaWorkersQuery.docs.length;
    
    // You can add more queries here for other statistics
    
    return {
      'ashaWorkers': ashaWorkersCount,
      // Add other stats here
    };
  } catch (e) {
    print('Error fetching village stats: $e');
    return {'ashaWorkers': 0};
  }
}




Widget _buildVillageStats() {
  final population = userData?['population']?.toString() ?? 'N/A';
  final houseHolds = userData?['houseHolds']?.toString() ?? 'N/A';
  
  return FutureBuilder<Map<String, dynamic>>(
    future: _fetchVillageStats(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      
      final stats = snapshot.data ?? {};
      final ashaWorkersCount = stats['ashaWorkers'] ?? 0;
      
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildStatCard('Population', population, Icons.people, const Color(0xFFFF9800)),
          _buildStatCard('Households', houseHolds, Icons.home, const Color(0xFF2196F3)),
          _buildStatCard('Water Sources', '6', Icons.water_drop, const Color(0xFF4CAF50)),
          _buildStatCard('Health Workers', '$ashaWorkersCount', Icons.medical_services, const Color(0xFFF44336)),
        ],
      );
    },
  );
}
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlerts() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var alert in _villageAlerts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.warning,
                    color: alert['priority'] == 'High' ? Colors.red : Colors.orange,
                  ),
                  title: Text(
                    alert['message'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${alert['type']} • ${alert['date']}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Chip(
                    label: Text(
                      alert['priority'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: alert['priority'] == 'High' ? Colors.red : Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterSourceStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var source in _waterSources)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.water_drop, color: Color(0xFF2196F3)),
                  title: Text(
                    source['name'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Last tested: ${source['lastTest']}',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Chip(
                    label: Text(
                      source['risk'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: source['risk'] == 'High'
                        ? Colors.red
                        : source['risk'] == 'Medium'
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVillageQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(Icons.warning, 'New Alert', () {
          _createNewAlert();
        }, const Color(0xFFFF9800)),
        _buildActionButton(Icons.campaign, 'Announcement', () {
          _makeAnnouncement();
        }, const Color(0xFF2196F3)),
        _buildActionButton(Icons.meeting_room, 'Call Meeting', () {
          _callCommunityMeeting();
        }, const Color(0xFF4CAF50)),
        _buildActionButton(Icons.notifications, 'Send Alert', () {
          _showVillageAlertDialog();
        }, Colors.blue),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWaterManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Water Resource Management',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop, size: 50, color: Color(0xFF2196F3)),
                    const SizedBox(height: 16),
                    Text(
                      'Water Source Management',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor and manage village water sources',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _manageWaterSources();
                      },
                      icon: const Icon(Icons.manage_accounts),
                      label: const Text('Manage Sources'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Water Source Status',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          ..._waterSources.map((source) => Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.water_drop, color: Color(0xFF2196F3)),
              title: Text(
                source['name'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Status: ${source['status']} • Last tested: ${source['lastTest']}',
                style: GoogleFonts.poppins(),
              ),
              trailing: Chip(
                label: Text(
                  source['risk'],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: source['risk'] == 'High'
                    ? Colors.red
                    : source['risk'] == 'Medium'
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Village Alerts & Notifications',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, size: 50, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Emergency Alert System',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send alerts to community members',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _sendEmergencyAlert();
                      },
                      icon: const Icon(Icons.notification_important),
                      label: const Text('Send Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Alerts',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          ..._villageAlerts.map((alert) => Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Icon(
                Icons.warning,
                color: alert['priority'] == 'High' ? Colors.red : Colors.orange,
              ),
              title: Text(
                alert['message'],
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${alert['type']} • ${alert['date']}',
                style: GoogleFonts.poppins(),
              ),
              trailing: Chip(
                label: Text(
                  alert['priority'],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: alert['priority'] == 'High' ? Colors.red : Colors.orange,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Community Management',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.people, size: 50, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    Text(
                      'Community Meetings',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schedule and manage community gatherings',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _scheduleMeeting();
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Schedule Meeting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.campaign, size: 50, color: Color(0xFF2196F3)),
                    const SizedBox(height: 16),
                    Text(
                      'Community Announcements',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make important announcements to the village',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _makeAnnouncement();
                      },
                      icon: const Icon(Icons.campaign),
                      label: const Text('Make Announcement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVillageAlertsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Village Alerts'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var alert in _villageAlerts)
                  Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: alert['priority'] == 'High' ? Colors.red : Colors.orange,
                        ),
                        title: Text(alert['message']),
                        subtitle: Text('${alert['type']} • ${alert['date']}'),
                      ),
                      const Divider(),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showVillageMap() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Village Map'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              children: [
                const Icon(Icons.map, size: 100, color: Colors.blue),
                const SizedBox(height: 16),
                const Text('Interactive village map showing:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('${_villageStats['waterSources']} Water Sources')),
                    Chip(label: Text('${_villageStats['healthWorkers']} Health Workers')),
                    Chip(label: Text('${_villageAlerts.length} Active Alerts')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showVillageQuickActions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Village Leader Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Issue Emergency Alert'),
                onTap: () {
                  Navigator.of(context).pop();
                  _createNewAlert();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.campaign, color: Colors.blue),
                title: const Text('Make Announcement'),
                onTap: () {
                  Navigator.of(context).pop();
                  _makeAnnouncement();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.meeting_room, color: Colors.green),
                title: const Text('Call Community Meeting'),
                onTap: () {
                  Navigator.of(context).pop();
                  _callCommunityMeeting();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: const Text('Manage Water Sources'),
                onTap: () {
                  Navigator.of(context).pop();
                  _manageWaterSources();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createNewAlert() {
    final TextEditingController alertController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedType = 'General';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: alertController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['General', 'Water', 'Health', 'Infrastructure']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedType = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Alert Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  items: ['Low', 'Medium', 'High']
                      .map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedPriority = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (alertController.text.isNotEmpty) {
                  setState(() {
                    _villageAlerts.insert(0, {
                      'type': selectedType,
                      'message': alertController.text,
                      'priority': selectedPriority,
                      'date': 'Just now'
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert created successfully!')),
                  );
                }
              },
              child: const Text('Create Alert'),
            ),
          ],
        );
      },
    );
  }

  void _makeAnnouncement() {
    final TextEditingController announcementController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Make Announcement'),
          content: TextField(
            controller: announcementController,
            decoration: const InputDecoration(
              labelText: 'Announcement Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (announcementController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Announcement sent: ${announcementController.text}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Send Announcement'),
            ),
          ],
        );
      },
    );
  }

  void _callCommunityMeeting() {
    final TextEditingController meetingController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Schedule Community Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: meetingController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting Topic',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Select Date'),
                  subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Select Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null) {
                      selectedTime = pickedTime;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (meetingController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Meeting scheduled: ${meetingController.text} on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedTime.format(context)}'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Schedule Meeting'),
            ),
          ],
        );
      },
    );
  }

  void _manageWaterSources() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manage Water Sources'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var source in _waterSources)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_drop),
                      title: Text(source['name']),
                      subtitle: Text('Status: ${source['status']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editWaterSource(source);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addNewWaterSource,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Water Source'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _editWaterSource(Map<String, dynamic> source) {
    final TextEditingController nameController = TextEditingController(text: source['name']);
    String selectedStatus = source['status'];
    String selectedRisk = source['risk'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Water Source'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Source Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ['Safe', 'Moderate', 'Contaminated']
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRisk,
                  items: ['Low', 'Medium', 'High']
                      .map((risk) => DropdownMenuItem(
                    value: risk,
                    child: Text(risk),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedRisk = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Risk Level',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  source['name'] = nameController.text;
                  source['status'] = selectedStatus;
                  source['risk'] = selectedRisk;
                  source['lastTest'] = 'Today';
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Water source updated!')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _addNewWaterSource() {
    final TextEditingController nameController = TextEditingController();
    String selectedStatus = 'Safe';
    String selectedRisk = 'Low';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Water Source'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Source Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ['Safe', 'Moderate', 'Contaminated']
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRisk,
                  items: ['Low', 'Medium', 'High']
                      .map((risk) => DropdownMenuItem(
                    value: risk,
                    child: Text(risk),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedRisk = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Risk Level',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _waterSources.add({
                      'name': nameController.text,
                      'status': selectedStatus,
                      'risk': selectedRisk,
                      'lastTest': 'Today'
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Water source added!')),
                  );
                }
              },
              child: const Text('Add Source'),
            ),
          ],
        );
      },
    );
  }

  void _sendEmergencyAlert() {
    final TextEditingController alertController = TextEditingController();
    String selectedPriority = 'High';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Emergency Alert'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: alertController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  items: ['High', 'Medium']
                      .map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedPriority = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (alertController.text.isNotEmpty) {
                  setState(() {
                    _villageAlerts.insert(0, {
                      'type': 'Emergency',
                      'message': alertController.text,
                      'priority': selectedPriority,
                      'date': 'Just now'
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency alert sent!')),
                  );
                }
              },
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  void _scheduleMeeting() {
    _callCommunityMeeting(); // Reuse the same functionality
  }

  void _showVillageAlertDialog() {
    final Map<String, String> alertTemplates = AlertSystem.getAlertTemplates('village_leader');
    String selectedTemplate = alertTemplates.keys.first;
    String customMessage = '';
    String selectedChannel = 'SMS';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Community Alert'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTemplate,
                      items: alertTemplates.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(key.replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTemplate = newValue!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Alert Type'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom Message (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        customMessage = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedChannel,
                      items: ['SMS', 'WhatsApp', 'IVR Call'].map((String channel) {
                        return DropdownMenuItem<String>(
                          value: channel,
                          child: Text(channel),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedChannel = newValue!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Channel'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String message = customMessage.isNotEmpty
                        ? customMessage
                        : alertTemplates[selectedTemplate]!;

                    // In a real app, you would have a list of community members' numbers
                    List<String> communityNumbers = ['+911234567890', '+919876543210'];

                    try {
                      for (String number in communityNumbers) {
                        if (selectedChannel == 'SMS') {
                          await AlertSystem.sendSMS(message, number);
                        } else if (selectedChannel == 'WhatsApp') {
                          await AlertSystem.sendWhatsApp(message, number);
                        } else if (selectedChannel == 'IVR Call') {
                          await AlertSystem.makeCall(number);
                        }
                      }

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Alert sent to community via $selectedChannel')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send alert: $e')),
                      );
                    }
                  },
                  child: const Text('Send to Community'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
class HealthOfficialDashboard extends StatefulWidget {
  const HealthOfficialDashboard({super.key});

  @override
  State<HealthOfficialDashboard> createState() => _HealthOfficialDashboardState();
}

class _HealthOfficialDashboardState extends State<HealthOfficialDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

// Mock data for Health Official
  final Map<String, dynamic> _districtStats = {
    'villages': 12,
    'population': 24500,
    'ashaWorkers': 28,
    'healthCenters': 4,
  };

  final List<Map<String, dynamic>> _outbreakAlerts = [
    {
      'id': 1,
      'village': 'Gandhi Nagar',
      'cases': 15,
      'disease': 'Diarrhea',
      'risk': 'High',
      'trend': 'Increasing',
      'status': 'Active'
    },
    {
      'id': 2,
      'village': 'Nehru Colony',
      'cases': 8,
      'disease': 'Typhoid',
      'risk': 'Medium',
      'trend': 'Stable',
      'status': 'Active'
    },
    {
      'id': 3,
      'village': 'Tagore Enclave',
      'cases': 5,
      'disease': 'Cholera',
      'risk': 'High',
      'trend': 'Increasing',
      'status': 'Active'
    },
  ];

  final List<Map<String, dynamic>> _resourceStatus = [
    {'resource': 'Medicines', 'status': 'Adequate', 'level': 85},
    {'resource': 'Testing Kits', 'status': 'Low', 'level': 25},
    {'resource': 'Purification Tablets', 'status': 'Adequate', 'level': 70},
    {'resource': 'Vaccines', 'status': 'Critical', 'level': 15},
  ];

// For analytics - mock time series for disease cases
  final Map<String, List<int>> _diseaseTrends = {
    'Diarrhea': [5, 7, 9, 12, 15],
    'Typhoid': [2, 3, 4, 6, 8],
    'Cholera': [0, 1, 2, 4, 5],
  };

  int _nextOutbreakId = 4;

  @override
// ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
// Navigate back to portal selection screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UserPortalScreen()),
            );
          },
        ),
        title: Text(
          'NIRAIVIZHI - Health Official Portal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showHealthAlertsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              _showAdvancedAnalytics();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFE1BEE7),
              Color(0xFFCE93D8),
            ],
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildHealthDashboard(),
            _buildOutbreaksTab(),
            _buildResourcesTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9C27B0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Outbreaks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showHealthQuickActions();
        },
        backgroundColor: const Color(0xFF9C27B0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

// ---------- Dashboard Page ----------
  Widget _buildHealthDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'District Health Overview',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            _buildDistrictStats(),
            const SizedBox(height: 24),
            Text(
              'Active Outbreak Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            _buildOutbreakAlerts(),
            const SizedBox(height: 24),
            Text(
              'Resource Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            _buildResourceStatus(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            _buildHealthQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictStats() {
    return Center(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildStatCard('Villages', '${_districtStats['villages']}', Icons.location_city, const Color(0xFF9C27B0)),
          _buildStatCard('Population', '${_districtStats['population']}', Icons.people, const Color(0xFF2196F3)),
          _buildStatCard('ASHA Workers', '${_districtStats['ashaWorkers']}', Icons.medical_services, const Color(0xFF4CAF50)),
          _buildStatCard('Health Centers', '${_districtStats['healthCenters']}', Icons.local_hospital, const Color(0xFFF44336)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// ---------- Outbreak Alerts List on Dashboard ----------
  Widget _buildOutbreakAlerts() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ..._outbreakAlerts.map((alert) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: () {
                      _openOutbreakDetails(alert);
                    },
                    leading: Icon(
                      Icons.warning,
                      color: alert['risk'] == 'High' ? Colors.red : Colors.orange,
                    ),
                    title: Text(
                      '${alert['village']} - ${alert['disease']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${alert['cases']} cases • Trend: ${alert['trend']} • Status: ${alert['status']}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Chip(
                      label: Text(
                        alert['risk'],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: alert['risk'] == 'High' ? Colors.red : Colors.orange,
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showDeclareOutbreakForm(),
                icon: const Icon(Icons.add_alert),
                label: const Text('Declare Outbreak'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ---------- Resource Status on Dashboard ----------
  Widget _buildResourceStatus() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ..._resourceStatus.map((resource) {
                final status = resource['status'] as String;
                final level = resource['level'] as int;
                final bgColor = status == 'Critical'
                    ? Colors.red
                    : status == 'Low'
                    ? Colors.orange
                    : Colors.green;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: () {
                      _showResourceDetails(resource);
                    },
                    leading: const Icon(Icons.inventory, color: Color(0xFF9C27B0)),
                    title: Text(
                      resource['resource'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: $status • Level: $level%',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Chip(
                      label: Text(
                        '$level%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: bgColor,
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _orderResources(),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Order Resource'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthQuickActions() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.warning, 'Outbreak Alert', () {
            _showDeclareOutbreakForm();
          }, const Color(0xFF9C27B0)),
          _buildActionButton(Icons.inventory, 'Order Resources', () {
            _orderResources();
          }, const Color(0xFF2196F3)),
          _buildActionButton(Icons.assignment, 'Generate Report', () {
            _generateHealthReport();
          }, const Color(0xFF4CAF50)),
          // CORRECTED: This button should call _showSendAlertDialog()
          _buildActionButton(Icons.notifications, 'Send Alert', () {
            _showSendAlertDialog();
          }, Colors.orange),
        ],
      ),
    );
  }

// Add this method to the _HealthOfficialDashboardState class
  void _showSendAlertDialog() {
    final Map<String, String> alertTemplates = AlertSystem.getAlertTemplates('health_official');
    String selectedTemplate = alertTemplates.keys.first;
    String customMessage = '';
    String selectedChannel = 'SMS';
    String recipientNumber = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Alert'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTemplate,
                      items: alertTemplates.keys.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(key.replaceAll('_', ' ')),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTemplate = newValue!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Alert Template'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Custom Message (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        customMessage = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedChannel,
                      items: ['SMS', 'WhatsApp', 'IVR Call'].map((String channel) {
                        return DropdownMenuItem<String>(
                          value: channel,
                          child: Text(channel),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedChannel = newValue!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Channel'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Recipient Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        recipientNumber = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String message = customMessage.isNotEmpty
                        ? customMessage
                        : alertTemplates[selectedTemplate]!;

                    try {
                      if (selectedChannel == 'SMS') {
                        await AlertSystem.sendSMS(message, recipientNumber);
                      } else if (selectedChannel == 'WhatsApp') {
                        await AlertSystem.sendWhatsApp(message, recipientNumber);
                      } else if (selectedChannel == 'IVR Call') {
                        await AlertSystem.makeCall(recipientNumber);
                      }

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Alert sent via $selectedChannel')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send alert: $e')),
                      );
                    }
                  },
                  child: const Text('Send Alert'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

// ---------- Outbreaks Tab ----------
  Widget _buildOutbreaksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Disease Outbreak Management',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Outbreak Response',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage and respond to disease outbreaks',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _manageOutbreakResponse();
                      },
                      icon: const Icon(Icons.emergency),
                      label: const Text('Outbreak Response'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Active Outbreaks',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            ..._outbreakAlerts.map((alert) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                onTap: () {
                  _openOutbreakDetails(alert);
                },
                leading: Icon(
                  Icons.warning,
                  color: alert['risk'] == 'High' ? Colors.red : Colors.orange,
                ),
                title: Text(
                  '${alert['village']} - ${alert['disease']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${alert['cases']} cases • Trend: ${alert['trend']} • Status: ${alert['status']}',
                  style: GoogleFonts.poppins(),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'resolve') {
                      _resolveOutbreak(alert['id']);
                    } else if (value == 'respond') {
                      _markInResponse(alert['id']);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'respond', child: Text('Mark In Response')),
                    const PopupMenuItem(value: 'resolve', child: Text('Mark Resolved')),
                  ],
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

// ---------- Resources Tab ----------
  Widget _buildResourcesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Resource Management',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.inventory, size: 50, color: Color(0xFF9C27B0)),
                    const SizedBox(height: 16),
                    Text(
                      'Resource Allocation',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage and allocate health resources',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _allocateResources();
                      },
                      icon: const Icon(Icons.dashboard),
                      label: const Text('Allocate Resources'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Current Resource Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            ..._resourceStatus.map((resource) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                onTap: () => _showResourceDetails(resource),
                leading: const Icon(Icons.inventory, color: Color(0xFF9C27B0)),
                title: Text(
                  resource['resource'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Status: ${resource['status']} • Level: ${resource['level']}%',
                  style: GoogleFonts.poppins(),
                ),
                trailing: Chip(
                  label: Text(
                    '${resource['level']}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: resource['status'] == 'Critical'
                      ? Colors.red
                      : resource['status'] == 'Low'
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

// ---------- Analytics Tab ----------
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Health Analytics & Reports',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7B1FA2),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.analytics, size: 50, color: Color(0xFF2196F3)),
                    const SizedBox(height: 16),
                    Text(
                      'District Health Report',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate comprehensive health reports',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _generateDistrictReport();
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('Generate Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up, size: 50, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    Text(
                      'Disease Trends',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyze disease patterns and trends',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _analyzeDiseaseTrends();
                      },
                      icon: const Icon(Icons.show_chart),
                      label: const Text('View Trends'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTrendsPreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsPreview() {
// Simple textual trend preview; you can swap with fl_chart visual
    return Column(
      children: _diseaseTrends.entries.map((entry) {
        final disease = entry.key;
        final series = entry.value;
        final latest = series.isNotEmpty ? series.last : 0;
        return ListTile(
          leading: const Icon(Icons.timeline),
          title: Text(disease, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          subtitle: Text('Recent cases: $latest • Series: ${series.join(', ')}'),
          trailing: ElevatedButton(
            onPressed: () {
              _showTrendDetail(disease, series);
            },
            child: const Text('Open'),
          ),
        );
      }).toList(),
    );
  }

// ---------- Dialogs & Actions Implementation ----------

// Health Alerts Dialog (top-right bell)
  void _showHealthAlertsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Health Department Alerts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Cholera outbreak in Tagore Enclave'),
                subtitle: const Text('Immediate intervention required'),
                trailing: TextButton(
                  child: const Text('Respond'),
                  onPressed: () {
                    Navigator.of(context).pop();
// find and mark Tagore Enclave in response
                    final found = _outbreakAlerts.where((a) => a['village'] == 'Tagore Enclave');
                    if (found.isNotEmpty) _markInResponse(found.first['id']);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Resource delivery tomorrow'),
                subtitle: const Text('Prepare storage facilities'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.green),
                title: const Text('Training session for ASHA workers'),
                subtitle: const Text('Schedule for next week'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

// Advanced analytics button (top-right)
  void _showAdvancedAnalytics() {
// For now navigate to analytics page
    setState(() {
      _currentIndex = 3;
      _pageController.jumpToPage(3);
    });
  }

// Quick actions FAB -> dialog with action choices
  void _showHealthQuickActions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Health Official Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Declare Outbreak'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeclareOutbreakForm();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.inventory, color: Colors.blue),
                title: const Text('Order Resources'),
                onTap: () {
                  Navigator.of(context).pop();
                  _orderResources();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.assignment, color: Colors.green),
                title: const Text('Generate Report'),
                onTap: () {
                  Navigator.of(context).pop();
                  _generateHealthReport();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.analytics, color: Colors.purple),
                title: const Text('View Analytics'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentIndex = 3;
                    _pageController.jumpToPage(3);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

// ---------- Declare Outbreak Form ----------
  void _showDeclareOutbreakForm() {
    final _formKey = GlobalKey<FormState>();
    String village = '';
    String disease = '';
    int cases = 1;
    String risk = 'Medium';
    String trend = 'Stable';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Declare New Outbreak'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Village'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter village' : null,
                    onSaved: (v) => village = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Disease'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter disease' : null,
                    onSaved: (v) => disease = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Number of Cases'),
                    keyboardType: TextInputType.number,
                    initialValue: '1',
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter valid cases';
                      return null;
                    },
                    onSaved: (v) => cases = int.parse(v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: risk,
                    items: const ['Low', 'Medium', 'High'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => risk = v ?? 'Medium',
                    decoration: const InputDecoration(labelText: 'Risk Level'),
                  ),
                  DropdownButtonFormField<String>(
                    value: trend,
                    items: const ['Decreasing', 'Stable', 'Increasing'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => trend = v ?? 'Stable',
                    decoration: const InputDecoration(labelText: 'Trend'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  setState(() {
                    _outbreakAlerts.insert(0, {
                      'id': _nextOutbreakId++,
                      'village': village,
                      'disease': disease,
                      'cases': cases,
                      'risk': risk,
                      'trend': trend,
                      'status': 'Active'
                    });
// update trend data mock
                    _diseaseTrends.putIfAbsent(disease, () => []);
                    _diseaseTrends[disease]!.add(cases);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outbreak declared')));
                }
              },
              child: const Text('Declare'),
            ),
          ],
        );
      },
    );
  }

// ---------- Outbreak details ----------
  void _openOutbreakDetails(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${alert['village']} — ${alert['disease']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cases: ${alert['cases']}'),
              Text('Risk: ${alert['risk']}'),
              Text('Trend: ${alert['trend']}'),
              Text('Status: ${alert['status']}'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markInResponse(alert['id']);
                },
                icon: const Icon(Icons.local_hospital),
                label: const Text('Mark In Response'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _resolveOutbreak(alert['id']);
                },
                icon: const Icon(Icons.check),
                label: const Text('Mark Resolved'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

// Mark outbreak in response
  void _markInResponse(int id) {
    setState(() {
      final idx = _outbreakAlerts.indexWhere((a) => a['id'] == id);
      if (idx != -1) {
        _outbreakAlerts[idx]['status'] = 'In Response';
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked In Response')));
      }
    });
  }

// Resolve outbreak
  void _resolveOutbreak(int id) {
    setState(() {
      final idx = _outbreakAlerts.indexWhere((a) => a['id'] == id);
      if (idx != -1) {
        _outbreakAlerts[idx]['status'] = 'Resolved';
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outbreak resolved')));
      }
    });
  }

// ---------- Resource ordering & details ----------
  void _orderResources() {
// Simple dialog to order a resource and increase its level
    String? selectedResource;
    int quantity = 10;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Resources'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                items: _resourceStatus.map((r) => r['resource'] as String).map((rname) => DropdownMenuItem(value: rname, child: Text(rname))).toList(),
                value: _resourceStatus.first['resource'] as String,
                onChanged: (v) => selectedResource = v,
                decoration: const InputDecoration(labelText: 'Select Resource'),
              ),
              TextFormField(
                initialValue: '10',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity (approx to increase %)'),
                onChanged: (v) {
                  final n = int.tryParse(v) ?? 10;
                  quantity = n;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final resourceName = selectedResource ?? _resourceStatus.first['resource'] as String;
                setState(() {
                  final idx = _resourceStatus.indexWhere((r) => r['resource'] == resourceName);
                  if (idx != -1) {
                    var current = _resourceStatus[idx]['level'] as int;
                    current = (current + quantity).clamp(0, 100);
                    _resourceStatus[idx]['level'] = current;
// update status field
                    _resourceStatus[idx]['status'] = current <= 15 ? 'Critical' : (current <= 40 ? 'Low' : 'Adequate');
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed and resource updated')));
              },
              child: const Text('Order'),
            ),
          ],
        );
      },
    );
  }

  void _showResourceDetails(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) {
        int adjust = 0;
        return AlertDialog(
          title: Text(resource['resource']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Level: ${resource['level']}%'),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Adjust level by (+/-)'),
                initialValue: '0',
                onChanged: (v) {
                  adjust = int.tryParse(v) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final idx = _resourceStatus.indexWhere((r) => r['resource'] == resource['resource']);
                  if (idx != -1) {
                    var newLevel = (_resourceStatus[idx]['level'] as int) + adjust;
                    newLevel = newLevel.clamp(0, 100);
                    _resourceStatus[idx]['level'] = newLevel;
                    _resourceStatus[idx]['status'] = newLevel <= 15 ? 'Critical' : (newLevel <= 40 ? 'Low' : 'Adequate');
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource updated')));
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

// ---------- Allocate resources flow (from Resources Tab) ----------
  void _allocateResources() {
    showDialog(
      context: context,
      builder: (context) {
        final Map<String, int> allocation = {};
        for (var r in _resourceStatus) allocation[r['resource']] = 0;

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Allocate Resources'),
            content: SingleChildScrollView(
              child: Column(
                children: _resourceStatus.map((r) {
                  final name = r['resource'] as String;
                  return Row(
                    children: [
                      Expanded(child: Text(name)),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: '0',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty %'),
                          onChanged: (v) {
                            allocation[name] = int.tryParse(v) ?? 0;
                          },
                        ),
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    allocation.forEach((name, qty) {
                      final idx = _resourceStatus.indexWhere((r) => r['resource'] == name);
                      if (idx != -1 && qty != 0) {
                        final int current = _resourceStatus[idx]['level'] as int;
                        final newLevel = (current + qty).clamp(0, 100);
                        _resourceStatus[idx]['level'] = newLevel;
                        _resourceStatus[idx]['status'] = newLevel <= 15 ? 'Critical' : (newLevel <= 40 ? 'Low' : 'Adequate');
                      }
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resources allocated')));
                },
                child: const Text('Allocate'),
              ),
            ],
          );
        });
      },
    );
  }

// ---------- Generate report (quick in-app summary) ----------
  void _generateHealthReport() {
    final outbreaks = _outbreakAlerts.where((a) => a['status'] != 'Resolved').length;
    final criticalResources = _resourceStatus.where((r) => r['status'] == 'Critical').length;

    final report = StringBuffer();
    report.writeln('=== District Health Report ===');
    report.writeln('Villages: ${_districtStats['villages']}');
    report.writeln('Population: ${_districtStats['population']}');
    report.writeln('ASHA Workers: ${_districtStats['ashaWorkers']}');
    report.writeln('Health Centers: ${_districtStats['healthCenters']}');
    report.writeln('');
    report.writeln('Active Outbreaks: $outbreaks');
    for (var a in _outbreakAlerts) {
      report.writeln('- ${a['village']}: ${a['disease']} (${a['cases']} cases) [${a['status']}]');
    }
    report.writeln('');
    report.writeln('Resource Status:');
    for (var r in _resourceStatus) {
      report.writeln('- ${r['resource']}: ${r['level']}% (${r['status']})');
    }
    report.writeln('');
    report.writeln('Critical resources count: $criticalResources');
    final reportText = report.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Health Report'),
          content: SingleChildScrollView(child: Text(reportText)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ElevatedButton(
              onPressed: () {
// Optional: export to PDF or share
// If you added pdf + printing packages, create a PDF here and print/share.
// Example (pseudo):
// final pdfDoc = pw.Document();
// pdfDoc.addPage(pw.Page(build: (c) => pw.Text(reportText)));
// Printing.layoutPdf(onLayout: (p) => pdfDoc.save());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report generated (view)')));
              },
              child: const Text('Export (optional)'),
            ),
          ],
        );
      },
    );
  }

// District level report (more official)
  void _generateDistrictReport() {
    _generateHealthReport();
  }

// ---------- Manage Outbreak response (opens quick action sheet) ----------
  void _manageOutbreakResponse() {
    if (_outbreakAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No outbreaks to manage')));
      return;
    }
// Open a selector for outbreaks and choose actions
    showDialog(
      context: context,
      builder: (context) {
        Map? chosen;
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Manage Outbreak Response'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<Map>(
                  isExpanded: true,
                  hint: const Text('Select outbreak'),
                  value: chosen,
                  items: _outbreakAlerts.map((o) {
                    return DropdownMenuItem<Map>(value: o, child: Text('${o['village']} — ${o['disease']} (${o['status']})'));
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      chosen = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: chosen == null
                      ? null
                      : () {
// simulate sending team
                    setState(() {
                      chosen!['status'] = 'In Response';
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical team dispatched')));
                  },
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Send Medical Team'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: chosen == null
                      ? null
                      : () {
                    setState(() {
                      chosen!['status'] = 'Awareness Campaign';
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Awareness campaign scheduled')));
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('Schedule Awareness'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: chosen == null
                      ? null
                      : () {
                    setState(() {
                      chosen!['status'] = 'Testing Scheduled';
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing scheduled')));
                  },
                  icon: const Icon(Icons.biotech),
                  label: const Text('Schedule Testing'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          );
        });
      },
    );
  }

// ---------- Analyze Disease Trends ----------
  void _analyzeDiseaseTrends() {
    setState(() {
      _currentIndex = 3;
      _pageController.jumpToPage(3);
    });
// Optionally perform trend computations here (not required for demo)
  }

  void _showTrendDetail(String disease, List<int> series) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$disease Trend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Series: ${series.join(', ')}'),
              const SizedBox(height: 8),
              Text('Latest: ${series.isNotEmpty ? series.last : 0}'),
              const SizedBox(height: 8),
              const Text('(Replace this section with a fl_chart line chart for a nicer visual)'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

// ---------- Helper: Show outbreak details and allow resolve/respond ----------
  void _showOutbreakOptions(Map<String, dynamic> outbreak) {
    _openOutbreakDetails(outbreak);
  }
}
class CommunityMemberDashboard extends StatefulWidget {
  const CommunityMemberDashboard({super.key});

  @override
  State<CommunityMemberDashboard> createState() => _CommunityMemberDashboardState();
}

class _CommunityMemberDashboardState extends State<CommunityMemberDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

// Mock data for Community Member
  final List<Map<String, dynamic>> _communityAlerts = [
    {'type': 'Water', 'message': 'Boil water before use in Sector B', 'priority': 'High', 'date': '2 hours ago'},
    {'type': 'Health', 'message': 'Free health check-up camp tomorrow', 'priority': 'Medium', 'date': '1 day ago'},
    {'type': 'General', 'message': 'Community meeting on Sunday', 'priority': 'Low', 'date': '2 days ago'},
  ];

  final List<Map<String, dynamic>> _waterSourceInfo = [
    {'name': 'Village Well', 'status': 'Unsafe', 'advice': 'Boil before use'},
    {'name': 'River Point', 'status': 'Safe', 'advice': 'Safe for drinking'},
    {'name': 'Hand Pump 1', 'status': 'Safe', 'advice': 'Safe for drinking'},
    {'name': 'Hand Pump 2', 'status': 'Moderate', 'advice': 'Filter before use'},
  ];

  final List<Map<String, dynamic>> _healthTips = [
    {'title': 'Safe Water Practices', 'content': 'Always boil or filter water before drinking'},
    {'title': 'Hand Hygiene', 'content': 'Wash hands with soap before eating and after using toilet'},
    {'title': 'Food Safety', 'content': 'Cook food thoroughly and eat while fresh'},
    {'title': 'Symptom Reporting', 'content': 'Report any health symptoms to ASHA worker immediately'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
// Navigate back to portal selection screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UserPortalScreen()),
            );
          },
        ),
        title: Text(
          'Community Portal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF44336),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showCommunityAlertsDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () {
              _showHelpDialog();
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFEBEE),
              Color(0xFFFFCDD2),
              Color(0xFFEF9A9A),
            ],
          ),
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildCommunityDashboard(),
            _buildAlertsTab(),
            _buildWaterInfoTab(),
            _buildHealthInfoTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF44336),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Water Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Health Info',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCommunityQuickActions();
        },
        backgroundColor: const Color(0xFFF44336),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCommunityDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Community Information',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            _buildCommunityStatus(),
            const SizedBox(height: 24),
            Text(
              'Recent Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentAlerts(),
            const SizedBox(height: 24),
            Text(
              'Water Source Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            _buildWaterSourceStatus(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            _buildCommunityQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityStatus() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.people, size: 50, color: Color(0xFFF44336)),
              SizedBox(height: 16),
              Text(
                'Community Health Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'No active outbreaks in your area',
                style: TextStyle(fontSize: 16, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Stay informed about water safety and health alerts',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var alert in _communityAlerts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.warning,
                      color: alert['priority'] == 'High' ? Colors.red :
                      alert['priority'] == 'Medium' ? Colors.orange : Colors.blue,
                    ),
                    title: Text(
                      alert['message'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${alert['type']} • ${alert['date']}',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterSourceStatus() {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var source in _waterSourceInfo)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.water_drop, color: Color(0xFF2196F3)),
                    title: Text(
                      source['name'],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Status: ${source['status']} • ${source['advice']}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Icon(
                      source['status'] == 'Unsafe' ? Icons.warning : Icons.check_circle,
                      color: source['status'] == 'Unsafe' ? Colors.red : Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityQuickActions() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.report, 'Report Symptoms', () {
            _reportSymptoms();
          }, const Color(0xFFF44336)),
          _buildActionButton(Icons.water_drop, 'Water Concern', () {
            _reportWaterConcern();
          }, const Color(0xFF2196F3)),
          _buildActionButton(Icons.help, 'Get Help', () {
            _getHelp();
          }, const Color(0xFF4CAF50)),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Community Alerts',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.notifications_active, size: 50, color: Color(0xFFF44336)),
                    const SizedBox(height: 16),
                    Text(
                      'Emergency Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Important notifications for your community',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Alerts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            ..._communityAlerts.map((alert) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(
                  Icons.warning,
                  color: alert['priority'] == 'High' ? Colors.red :
                  alert['priority'] == 'Medium' ? Colors.orange : Colors.blue,
                ),
                title: Text(
                  alert['message'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${alert['type']} • ${alert['date']}',
                  style: GoogleFonts.poppins(),
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }


  Widget _buildWaterInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Water Safety Information',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop, size: 50, color: Color(0xFF2196F3)), // Fixed: Icles -> Icons
                    const SizedBox(height: 16),
                    Text(
                      'Water Source Status',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current status of water sources in your area',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Water Sources',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            ..._waterSourceInfo.map((source) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.water_drop, color: Color(0xFF2196F3)),
                title: Text(
                  source['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Status: ${source['status']} • ${source['advice']}',
                  style: GoogleFonts.poppins(),
                ),
                trailing: Icon(
                  source['status'] == 'Unsafe' ? Icons.warning : Icons.check_circle,
                  color: source['status'] == 'Unsafe' ? Colors.red : Colors.green,
                ),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Health Information',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.health_and_safety, size: 50, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    Text(
                      'Health Tips & Guidance',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Important health information for your family',
                      style: GoogleFonts.poppins(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Health Tips',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 16),
            ..._healthTips.map((tip) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.lightbulb, color: Color(0xFFFFC107)),
                title: Text(
                  tip['title'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(tip['content']),
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _showCommunityAlertsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Community Alerts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Boil water before use in Sector B'),
                subtitle: const Text('Due to contamination concerns'),
                onTap: () {
                  Navigator.of(context).pop();
// Additional action if needed
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Free health camp tomorrow'),
                subtitle: const Text('At community center, 10 AM - 4 PM'),
                onTap: () {
                  Navigator.of(context).pop();
// Additional action if needed
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.green),
                title: const Text('Community meeting on Sunday'),
                subtitle: const Text('Discuss water safety measures'),
                onTap: () {
                  Navigator.of(context).pop();
// Additional action if needed
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Need Help?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.green),
                title: const Text('Contact ASHA Worker'),
                subtitle: const Text('For health concerns and symptoms'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getHelp();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text('Contact Village Leader'),
                subtitle: const Text('For community issues and alerts'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getHelp();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.emergency, color: Colors.red),
                title: const Text('Emergency Services'),
                subtitle: const Text('Call 108 for medical emergencies'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getHelp();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showCommunityQuickActions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Community Actions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('Report Symptoms'),
                onTap: () {
                  Navigator.of(context).pop();
                  _reportSymptoms();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blue),
                title: const Text('Report Water Concern'),
                onTap: () {
                  Navigator.of(context).pop();
                  _reportWaterConcern();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help, color: Colors.green),
                title: const Text('Get Help'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getHelp();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.purple),
                title: const Text('View Health Tips'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _currentIndex = 3;
                    _pageController.jumpToPage(3);
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _reportSymptoms() {
    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        String name = '';
        String symptoms = '';
        String duration = '';

        return AlertDialog(
          title: const Text('Report Symptoms'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Your Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                    onSaved: (v) => name = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Symptoms'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe symptoms' : null,
                    onSaved: (v) => symptoms = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Duration'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter duration' : null,
                    onSaved: (v) => duration = v!.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Symptoms reported successfully')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _reportWaterConcern() {
    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();
        String location = '';
        String concern = '';

        return AlertDialog(
          title: const Text('Report Water Concern'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null,
                    onSaved: (v) => location = v!.trim(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Concern Description'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe the concern' : null,
                    onSaved: (v) => concern = v!.trim(),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Water concern reported successfully')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _getHelp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Get Help'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact information for assistance:'),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('ASHA Worker: 98765-43210'),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.blue),
                title: Text('Health Center: 0123-456789'),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.red),
                title: Text('Emergency: 108'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
// Add this import at the top of your file with other imports

// HydroBot Integration Wrapper
// OPTIMUS-X Integration Wrapper


void Main() {
  runApp(OptimusXApp());
}

class OptimusXApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OPTIMUS-X',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF0A0E21),
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _splashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _fadeController;
  late AnimationController _taglineController;

  late Animation<double> _drawAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _taglineAnimation;

  @override
  void initState() {
    super.initState();

    // "O" drawing animation
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeInOutCubic,
    );

    // Fade in OPTIMUS-X text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Fade in Tagline
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _taglineAnimation = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    // Sequence animations
    _drawController.forward().whenComplete(() {
      _fadeController.forward().whenComplete(() {
        _taglineController.forward();
      });
    });

    // Navigate after splash (extended to 6 seconds total)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _fadeController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF0A0A1A)], // Fully dark background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated "O" for OPTIMUS-X
              AnimatedBuilder(
                animation: _drawAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: FancyOPainter(progress: _drawAnimation.value),
                    size: const Size(200, 200),
                  );
                },
              ),

              const SizedBox(height: 30),

              // OPTIMUS-X
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  "OPTIMUS-X",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: Colors.cyanAccent.withOpacity(0.9),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Smart Sabarmati Riverfront & Urban Water Bodies (tagline)
              FadeTransition(
                opacity: _taglineAnimation,
                child: Text(
                  "Smart Sabarmati Riverfront & Urban Water Bodies",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Painter to draw glowing Aqua "O" for OPTIMUS-X
class FancyOPainter extends CustomPainter {
  final double progress; // expected 0.0 - 1.0
  FancyOPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      colors: [Colors.cyanAccent, Colors.blueAccent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Create a circular "O" path
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw a stylish "O" - circular shape with a small gap at the top
    path.addArc(Rect.fromCircle(center: center, radius: radius), 0, 2 * math.pi * 0.95);

    final p = progress.clamp(0.0, 1.0);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    double totalLength = metrics.fold(0, (sum, m) => sum + m.length);

    double drawLength = totalLength * p;
    final drawnPath = Path();

    for (final metric in metrics) {
      if (drawLength <= 0) break;
      final take = math.min(metric.length, drawLength);
      drawnPath.addPath(metric.extractPath(0.0, take), Offset.zero);
      drawLength -= take;
    }

    canvas.drawPath(drawnPath, paint);

    // Add a glowing effect in the center when animation completes
    if (progress > 0.8) {
      final glowPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity((progress - 0.8) * 5 * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);

      canvas.drawCircle(center, radius * 0.6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FancyOPainter old) => old.progress != progress;
}
/// Custom Route Transition (for Back to Portal & Login)
class FadeSlidePageRoute extends PageRouteBuilder {
  final Widget page;
  FadeSlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.2); // Slide from bottom
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween =
                Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

class LoginScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Professional Dark Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF334155),
                ],
              ),
            ),
          ),

          /// Subtle Background Accents
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.08),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.06),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          /// Main Content
          SafeArea(
            child: Column(
              children: [
                /// Header with Back Button
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Navigate to UserPortalScreen using pushReplacement
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => UserPortalScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20, color: Colors.white70),
                          tooltip: 'Back to Portal',
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Back to Portal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /// Login Card
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  /// Logo and Title Section
                                  Container(
                                    padding: EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Icon(Icons.security_rounded,
                                              size: 40, 
                                              color: Colors.blueAccent),
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          "HYDROBOT ACCESS",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Control Panel Login",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 40),

                                  /// Login Form
                                  Column(
                                    children: [
                                      /// Username Field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _usernameController,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.07),
                                            labelText: 'Username',
                                            labelStyle: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.blueAccent,
                                                width: 1.5,
                                              ),
                                            ),
                                            prefixIcon: Icon(Icons.person_outline,
                                                color: Colors.white54),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),

                                      /// Password Field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _passwordController,
                                          obscureText: true,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.07),
                                            labelText: 'Password',
                                            labelStyle: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.blueAccent,
                                                width: 1.5,
                                              ),
                                            ),
                                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                                color: Colors.white54),
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  /// Credentials Hint
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded,
                                            size: 16, color: Colors.orangeAccent),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Default credentials: admin / 123456',
                                            style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 32),

                                  /// Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: Material(
                                      borderRadius: BorderRadius.circular(12),
                                      elevation: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blueAccent,
                                              Colors.blue.shade700,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _performLogin(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Text(
                                            "Login to System",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 24),

                                  /// Footer Links
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          _showForgotPasswordDialog(context);
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white70,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 14,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _performLogin(BuildContext context) {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar(context, 'Please enter both username and password', Colors.orange);
      return;
    }

    if (username == 'admin' && password == '123456') {
      // Success - navigate to home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OptimusXHomePage()),
      );
    } else {
      _showSnackBar(context, 'Invalid credentials. Use admin/123456', Colors.red);
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Password Assistance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Please contact your system administrator or IT support team to reset your password.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(20),
      ),
    );
  }
}

class OptimusXHomePage extends StatefulWidget {
  @override
  _OptimusXHomePageState createState() => _OptimusXHomePageState();
}

class _OptimusXHomePageState extends State<OptimusXHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late Timer _dataUpdateTimer;

  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensor');
  Timer? _timer;
  
  // Sensor data variables - using only the ones from Firebase
  double tdsValue = 0.0;
  double temperature = 0.0;
  double turbidity = 0.0;
  double gasValue = 0.0;
  double pHValue = 0.0;
  double _obstacleDistance = 500.0; // in cm

  DateTime? lastUpdated;
  
  bool isLoading = false;
  String errorMessage = '';
  int fetchCount = 0;

  // Other existing variables
  int _trashCollected = 1250;
  int _hyacinthProcessed = 870;
  double _conveyor1Speed = 0.5;
  double _conveyor2Speed = 0.5;
  bool _shredderActive = false;
  bool _compactorActive = false;
  bool _isRobotOn = true;
  bool _obstacleDetected = false;
  double _batteryLevel = 82.0;
  double _solarVoltage = 18.5;

  final List<String> _titles = [
    'OPTIMUS-X ',
    'Bot Details',
    'Dual Conveyor Control',
    'Live Trash Analytics',
    'Hyacinth Processing',
    'Obstacle Detection',
    'Flood Risk Alert',
    'Smart Charging',
    'AI-Powered Vision',
    'PH Testing',
    'Turbidity Testing',
    'Total Dissolved Solids',
    'Eco-Disposal Methods',
    'Predictive Analytics',
    'Fleet Management',
    'Citizen Portal',
    'Contact',
    'Judges FAQ',
    'Logout'
  ];

  @override
  void initState() {
    super.initState();
    _startPolling();
    
    _dataUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Only update non-sensor data
          _updateNonSensorData();
        });
      }
    });
  }

  void _startPolling() {
    // Fetch immediately
    _fetchSensorData();
    
    // Then fetch every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      _fetchSensorData();
    });
  }

  Future<void> _fetchSensorData() async {
    if (isLoading) return;
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      DatabaseEvent event = await _sensorRef.once();
      DataSnapshot snapshot = event.snapshot;
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        setState(() {
          // Parse sensor values with safety checks
          tdsValue = _parseDouble(data['Tds value']);
          temperature = _parseDouble(data['Temperature']);
          turbidity = _parseDouble(data['Turbidity']);
          gasValue = _parseDouble(data['gasValue']);
          pHValue = _parseDouble(data['pHValue']);
          _obstacleDistance = _parseDouble(data['ultrasonic']);
          lastUpdated = DateTime.now();
          if(temperature == -127){
            temperature = 26;
          }
          fetchCount++;
          isLoading = false;
        });
        
        print('Sensor data fetched at ${DateTime.now()}');
        print('TDS: $tdsValue, Temp: $temperature, Turbidity: $turbidity, Gas: $gasValue, pH: $pHValue');
      } else {
        setState(() {
          errorMessage = 'No sensor data found in database';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error fetching data: $error';
        isLoading = false;
      });
      print('Error fetching sensor data: $error');
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _updateNonSensorData() {
    final random = Random();
    // Only update non-sensor data
    _trashCollected += random.nextInt(5);
    _hyacinthProcessed += random.nextInt(3);
    _obstacleDetected = random.nextDouble() > 0.7;
    _batteryLevel = (80 + random.nextDouble() * 15).clamp(0, 100);
    _solarVoltage = 18 + random.nextDouble() * 2;
  }
Widget _getScreenForIndex(int index) {
  switch (index) {
    case 0: return _buildDashboard();
    case 1: return BotDetailsScreen(onNext: () => setState(() => _selectedIndex = 2));
    case 2: return DualConveyorControlScreen(
      conveyor1Speed: _conveyor1Speed,
      conveyor2Speed: _conveyor2Speed,
      shredderActive: _shredderActive,
      compactorActive: _compactorActive,
      onSpeedChange: (c1, c2, shred, comp) {
        setState(() {
          _conveyor1Speed = c1;
          _conveyor2Speed = c2;
          _shredderActive = shred;
          _compactorActive = comp;
        });
      },
      onNext: () => setState(() => _selectedIndex = 3),
    );
    case 3: return LiveTrashAnalyticsScreen(
      trashCollected: _trashCollected,
      onNext: () => setState(() => _selectedIndex = 4),
    );
    case 4: return HyacinthProcessingScreen(
      hyacinthProcessed: _hyacinthProcessed,
      onNext: () => setState(() => _selectedIndex = 5),
    );
    case 5: return ObstacleDetectionScreen(
      obstacleDistance: _obstacleDistance, // ADD THIS LINE - pass the real data
      onNext: () => setState(() => _selectedIndex = 6),
    );
    case 6: return FloodRiskAlertScreen(
      waterLevel: _batteryLevel,
      onNext: () => setState(() => _selectedIndex = 7),
    );
    case 7: return SmartChargingScreen(
      batteryLevel: _batteryLevel,
      solarVoltage: _solarVoltage,
      onNext: () => setState(() => _selectedIndex = 8),
    );
    case 8: return AIVisionScreen(onNext: () => setState(() => _selectedIndex = 9));
    case 9: return PHTestingScreen(phLevel: pHValue, onNext: () => setState(() => _selectedIndex = 10));
    case 10: return TurbidityTestingScreen(turbidity: turbidity, onNext: () => setState(() => _selectedIndex = 11));
    case 11: return TDSTestingScreen(tds: tdsValue, onNext: () => setState(() => _selectedIndex = 12));
    case 12: return EcoDisposalMethodsScreen(onNext: () => setState(() => _selectedIndex = 13));
    case 13: return PredictiveAnalyticsScreen(onNext: () => setState(() => _selectedIndex = 14));
    case 14: return FleetManagementScreen(onNext: () => setState(() => _selectedIndex = 15));
    case 15: return CitizenPortalScreen(onNext: () => setState(() => _selectedIndex = 16));
    case 16: return ContactScreen(onNext: () => setState(() => _selectedIndex = 17));
    case 17: return JudgesFAQScreen(onNext: () => setState(() => _selectedIndex = 18));
    case 18: return LogoutScreen(onLogoutComplete: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
    default: return _buildDashboard();
  }
}

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Futuristic Header Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E21), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 6),
                )
              ],
              border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OPTIMUS-X SYSTEM',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Real-time Monitoring Active',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Last update: ${lastUpdated != null ? _formatTime(lastUpdated!) : "Never"}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    // Robot On/Off Switch
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isRobotOn 
                                  ? [Colors.greenAccent.withOpacity(0.3), Colors.green.withOpacity(0.1)]
                                  : [Colors.redAccent.withOpacity(0.3), Colors.red.withOpacity(0.1)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: _isRobotOn ? Colors.greenAccent : Colors.redAccent, width: 2),
                          ),
                          child: Icon(
                            _isRobotOn ? Icons.verified : Icons.error,
                            color: _isRobotOn ? Colors.greenAccent : Colors.redAccent,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: 8),
                        // Toggle Switch
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRobotOn = !_isRobotOn;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isRobotOn ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _isRobotOn ? Colors.greenAccent : Colors.redAccent),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isRobotOn ? Icons.power_settings_new : Icons.power_off,
                                  color: _isRobotOn ? Colors.greenAccent : Colors.redAccent,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _isRobotOn ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    color: _isRobotOn ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFuturisticStatCard('Bots Active', '8', Icons.engineering, Colors.cyanAccent),
                    _buildFuturisticStatCard('Trash Collected', '${_trashCollected}kg', Icons.cleaning_services, Colors.greenAccent),
                    _buildFuturisticStatCard('Efficiency', '94%', Icons.auto_awesome, Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // System Control Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                )
              ],
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.1), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('System Control', style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    )),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isRobotOn 
                                  ? [Colors.greenAccent, Colors.green]
                                  : [Colors.redAccent, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isRobotOn ? 'ACTIVE' : 'STANDBY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isRobotOn,
                            onChanged: (value) {
                              setState(() {
                                _isRobotOn = value;
                              });
                            },
                            activeColor: Colors.greenAccent,
                            activeTrackColor: Colors.greenAccent.withOpacity(0.5),
                            inactiveThumbColor: Colors.redAccent,
                            inactiveTrackColor: Colors.redAccent.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Battery Level', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Text('${_batteryLevel.toStringAsFixed(1)}%', 
                             style: TextStyle(color: _getBatteryColor(_batteryLevel), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          height: 8,
                          width: MediaQuery.of(context).size.width * (_batteryLevel / 100) * 0.7,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getBatteryColor(_batteryLevel),
                                _getBatteryColor(_batteryLevel).withOpacity(0.7)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: _getBatteryColor(_batteryLevel).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniMetric('Solar', '${_solarVoltage.toStringAsFixed(1)}V', Icons.wb_sunny, Colors.orangeAccent),
                    _buildMiniMetric('Gas', '${gasValue.toStringAsFixed(1)}', Icons.air, Colors.greenAccent),
                    _buildMiniMetric('pH', pHValue.toStringAsFixed(1), Icons.science, _getPHColor(pHValue)),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Quick Actions Section (unchanged)
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _onSelectItem(1),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.engineering, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Bot Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                          ),
                          child: Text(
                            'Robot Specifications',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ... (other quick action containers remain the same)
              ],
            ),
          ),

          SizedBox(height: 20),
          
          // Ecosystem Metrics - Using only real sensor data
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LIVE SENSOR DATA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.sensors, color: Colors.greenAccent, size: 16),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                _buildFuturisticMetricRow('Temperature', temperature, '°C', Colors.orangeAccent, Icons.thermostat),
                _buildFuturisticMetricRow('pH Level', pHValue, '', _getPHColor(pHValue), Icons.science),
                _buildFuturisticMetricRow('Turbidity', turbidity, 'NTU', Colors.blueAccent, Icons.opacity),
                _buildFuturisticMetricRow('TDS', tdsValue, 'ppm', Colors.purpleAccent, Icons.linear_scale),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Next Page Button
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _onSelectItem(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'NEXT: BOT DETAILS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  Widget _buildFuturisticStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(value, style: TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          )),
          Text(title, style: TextStyle(
            color: Colors.white70, 
            fontSize: 10,
            letterSpacing: 0.8,
          )),
        ],
      ),
    );
  }

  Widget _buildFuturisticMetricRow(String label, double value, String unit, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(label, 
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Text('${value.toStringAsFixed(1)}$unit', 
              style: TextStyle(
                color: color, 
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              )),
          SizedBox(width: 10),
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value / (label == 'TDS' ? 1000 : 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)]
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            SizedBox(width: 4),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getBatteryColor(double level) {
    if (level > 70) return Colors.greenAccent;
    if (level > 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getPHColor(double ph) {
    if (ph < 6.5) return Colors.redAccent;
    if (ph > 8.5) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1)),
        backgroundColor: Color(0xFF1A237E),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: _selectedIndex == 0 ? [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchSensorData,
            tooltip: 'Refresh Sensor Data',
          ),
        ] : null,
      ),
      drawer: _buildDrawer(),
      body: _getScreenForIndex(_selectedIndex),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Color(0xFF1E1E2C),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 48, color: Colors.white),
                SizedBox(height: 10),
                Text('OPTIMUS-X', 
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Admin Dashboard', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ...List.generate(_titles.length, (index) {
            return ListTile(
              leading: Icon(_getIconForIndex(index), color: Colors.blueAccent),
              title: Text(_titles[index], style: TextStyle(color: Colors.white)),
              selected: _selectedIndex == index,
              onTap: () => _onSelectItem(index),
              tileColor: _selectedIndex == index ? Colors.blueAccent.withOpacity(0.1) : null,
            );
          }),
        ],
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.dashboard;
      case 1: return Icons.engineering;
      case 2: return Icons.conveyor_belt;
      case 3: return Icons.analytics;
      case 4: return Icons.grass;
      case 5: return Icons.warning;
      case 6: return Icons.flood;
      case 7: return Icons.bolt;
      case 8: return Icons.camera_alt;
      case 9: return Icons.air;
      case 10: return Icons.science;
      case 11: return Icons.opacity;
      case 12: return Icons.water;
      case 13: return Icons.recycling;
      case 14: return Icons.trending_up;
      case 15: return Icons.directions_boat;
      case 16: return Icons.people;
      case 17: return Icons.contact_page;
      case 18: return Icons.quiz;
      case 19: return Icons.logout;
      default: return Icons.circle;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dataUpdateTimer.cancel();
    super.dispose();
  }
}
class BotDetailsScreen extends StatelessWidget {
  final VoidCallback onNext;

  BotDetailsScreen({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.engineering, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Fleet Management', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('8 Active Bots', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final botStatus = ['Active', 'Charging', 'Maintenance'][index % 3];
                final batteryLevel = 20 + Random().nextInt(80);
                return Card(
                  color: Color(0xFF1E1E2C),
                  child: InkWell(
                    onTap: () => _showBotDetails(context, index + 1, botStatus, batteryLevel),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blueAccent.withOpacity(0.3), Colors.tealAccent.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.engineering, size: 50, color: Colors.blueAccent),
                                  SizedBox(height: 10),
                                  Text('OPTIMUS-${index + 1}', 
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(botStatus).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(botStatus, 
                                        style: TextStyle(color: _getStatusColor(botStatus), fontSize: 10)),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              LinearProgressIndicator(
                                value: batteryLevel / 100,
                                backgroundColor: Colors.white24,
                                color: _getBatteryColor(batteryLevel.toDouble()),
                              ),
                              SizedBox(height: 5),
                              Text('$batteryLevel%', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(Icons.arrow_forward),
              label: Text('Next: Conveyor Control'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return Colors.greenAccent;
      case 'Charging': return Colors.orangeAccent;
      case 'Maintenance': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Color _getBatteryColor(double level) {
    if (level > 70) return Colors.greenAccent;
    if (level > 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showBotDetails(BuildContext context, int botNumber, String status, int battery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('OPTIMUS-$botNumber Details', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', status, _getStatusColor(status)),
              _buildDetailRow('Battery', '$battery%', _getBatteryColor(battery.toDouble())),
              _buildDetailRow('Location', 'Zone ${['A', 'B', 'C', 'D'][botNumber % 4]}', Colors.blueAccent),
              _buildDetailRow('Tasks Completed', '${Random().nextInt(100)}', Colors.greenAccent),
              _buildDetailRow('Uptime', '${120 + Random().nextInt(200)} hours', Colors.orangeAccent),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Enhanced screens with professional UI (showing a few examples - others follow similar pattern)
class LiveTrashAnalyticsScreen extends StatefulWidget {
  final int trashCollected;
  final VoidCallback onNext;

  const LiveTrashAnalyticsScreen({Key? key, required this.trashCollected, required this.onNext}) : super(key: key);

  @override
  _LiveTrashAnalyticsScreenState createState() => _LiveTrashAnalyticsScreenState();
}

class _LiveTrashAnalyticsScreenState extends State<LiveTrashAnalyticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  int _animatedTrashCount = 0;
  double _efficiency = 94.2;
  int _activeStations = 12;
  bool _isRealTime = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.trashCollected.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    _progressAnimation.addListener(() {
      setState(() {
        _animatedTrashCount = _progressAnimation.value.toInt();
      });
    });

    // Simulate real-time updates
    if (_isRealTime) {
      Timer.periodic(Duration(seconds: 5), (timer) {
        if (mounted) {
          setState(() {
            _efficiency = 94.2 + Random().nextDouble() * 2 - 1;
            _activeStations = 12 + Random().nextInt(3) - 1;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F111C),
      body: Column(
        children: [
          // Enhanced Header Section
          Container(
            padding: EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.analytics, size: 32, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Live Trash Analytics', 
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Real-time monitoring dashboard',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isRealTime ? Colors.greenAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isRealTime ? Colors.greenAccent : Colors.orangeAccent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: _isRealTime ? Colors.greenAccent : Colors.orangeAccent),
                          SizedBox(width: 6),
                          Text(_isRealTime ? 'LIVE' : 'PAUSED', 
                              style: TextStyle(color: _isRealTime ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                _buildStatsHeader(),
              ],
            ),
          ),
          
          // Main Analytics Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Key Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _buildMetricCard(
                          'Total Collected',
                          '$_animatedTrashCount kg',
                          Icons.cleaning_services,
                          Colors.greenAccent,
                          '↑ 12% from yesterday',
                          Colors.greenAccent,
                        ),
                        _buildMetricCard(
                          'Efficiency Rate',
                          '${_efficiency.toStringAsFixed(1)}%',
                          Icons.auto_awesome,
                          Colors.blueAccent,
                          'Optimal performance',
                          Colors.blueAccent,
                        ),
                        _buildMetricCard(
                          'Active Stations',
                          '$_activeStations/15',
                          Icons.location_on,
                          Colors.orangeAccent,
                          '${((_activeStations / 15) * 100).toStringAsFixed(0)}% operational',
                          Colors.orangeAccent,
                        ),
                        _buildMetricCard(
                          'Volume Processed',
                          '${(_animatedTrashCount * 1.2).toStringAsFixed(0)}L',
                          Icons.water_drop,
                          Colors.tealAccent,
                          'Water volume equivalent',
                          Colors.tealAccent,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Progress Analytics Card
                    _buildProgressCard(),
                    SizedBox(height: 16),
                    
                    // Efficiency Breakdown Card
                    _buildEfficiencyCard(),
                    SizedBox(height: 16),
                    
                    // Collection Timeline
                    _buildTimelineCard(),
                  ],
                ),
              ),
            ),
          ),
          
          // Control Panel
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(Icons.refresh, 'Refresh', Colors.blueAccent, () {
                      setState(() {
                        _animationController.reset();
                        _animationController.forward();
                      });
                    }),
                    _buildControlButton(
                      _isRealTime ? Icons.pause : Icons.play_arrow, 
                      _isRealTime ? 'Pause' : 'Resume', 
                      _isRealTime ? Colors.orangeAccent : Colors.greenAccent, 
                      () {
                        setState(() {
                          _isRealTime = !_isRealTime;
                        });
                      }
                    ),
                    _buildControlButton(Icons.download, 'Export', Colors.purpleAccent, () {
                      _showExportDialog(context);
                    }),
                  ],
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: widget.onNext,
                  icon: Icon(Icons.arrow_forward, size: 20),
                  label: Text('Next: Hyacinth Processing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Today', '${widget.trashCollected}kg', Icons.today),
          _buildStatItem('Weekly', '320kg', Icons.calendar_view_week),
          _buildStatItem('Monthly', '1.2t', Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Icon(Icons.more_vert, size: 16, color: Colors.white54),
              ],
            ),
            SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text('Collection Progress', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Target: 100kg', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${(_animatedTrashCount / 100 * 100).toStringAsFixed(0)}%', 
                    style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _animatedTrashCount / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0kg', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('100kg', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text('Efficiency Breakdown', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            _buildEfficiencyBar('Collection', 94.2, Colors.greenAccent),
            _buildEfficiencyBar('Processing', 88.5, Colors.blueAccent),
            _buildEfficiencyBar('Transport', 91.3, Colors.orangeAccent),
            _buildEfficiencyBar('Disposal', 96.7, Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyBar(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text('${value.toStringAsFixed(1)}%', 
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.orangeAccent, size: 20),
                SizedBox(width: 8),
                Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            _buildTimelineItem('Collection completed', 'Station #4', '2 min ago', Icons.check_circle, Colors.greenAccent),
            _buildTimelineItem('Maintenance alert', 'Station #7', '5 min ago', Icons.warning, Colors.orangeAccent),
            _buildTimelineItem('New collection started', 'Station #2', '8 min ago', Icons.play_arrow, Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String time, IconData icon, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 10)),
      trailing: Text(time, style: TextStyle(color: Colors.white54, fontSize: 10)),
    );
  }

  Widget _buildControlButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            icon: Icon(icon, size: 20, color: color),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('Export Data', style: TextStyle(color: Colors.white)),
        content: Text('Choose export format:', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Export CSV'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Export PDF'),
          ),
        ],
      ),
    );
  }
}
// Similar professional implementations for other screens...

class HyacinthProcessingScreen extends StatelessWidget {
  final int hyacinthProcessed;
  final VoidCallback onNext;

  const HyacinthProcessingScreen({Key? key, required this.hyacinthProcessed, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.grass, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Hyacinth Processing', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Water hyacinth processing and biogas conversion',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Processing Cards Section - Each in separate row
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Processed Today - Single row
                    _buildProcessCard(
                      'Processed Today', 
                      '$hyacinthProcessed kg', 
                      Icons.assessment, 
                      Colors.greenAccent,
                      'Current processing volume'
                    ),
                    SizedBox(height: 15),
                    
                    // Shredding Rate - Single row
                    _buildProcessCard(
                      'Shredding Rate', 
                      '15 kg/hour', 
                      Icons.speed, 
                      Colors.blueAccent,
                      'Average shredding capacity'
                    ),
                    SizedBox(height: 15),
                    
                    // Efficiency - Single row
                    _buildProcessCard(
                      'Efficiency', 
                      '92%', 
                      Icons.auto_awesome, 
                      Colors.orangeAccent,
                      'Processing efficiency rate'
                    ),
                    SizedBox(height: 15),
                    
                    // Biogas Output - Single row
                    _buildProcessCard(
                      'Biogas Output', 
                      '${(hyacinthProcessed * 0.3).toStringAsFixed(1)} kWh', 
                      Icons.bolt, 
                      Colors.yellowAccent,
                      'Energy generation from biomass'
                    ),
                    SizedBox(height: 15),
                    
                    // Processing Capacity - Single row
                    _buildProcessCard(
                      'Processing Capacity', 
                      '85% Utilized', 
                      Icons.storage, 
                      Colors.purpleAccent,
                      'Current capacity utilization'
                    ),
                    SizedBox(height: 15),
                    
                    // Quality Score - Single row
                    _buildProcessCard(
                      'Quality Score', 
                      '8.7/10', 
                      Icons.stay_current_portrait_rounded, 
                      Colors.tealAccent,
                      'Output quality rating'
                    ),
                    SizedBox(height: 15),
                    
                    // Processing Progress Card - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.timeline, color: Colors.greenAccent),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Daily Target Progress', 
                                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                                      Text('${(hyacinthProcessed / 200 * 100).toStringAsFixed(0)}% Complete', 
                                          style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: hyacinthProcessed / 200,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                              minHeight: 6,
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0 kg', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                Text('200 kg target', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Refresh', Colors.blueAccent),
                    _buildActionButton(Icons.analytics, 'Analytics', Colors.greenAccent),
                    _buildActionButton(Icons.history, 'History', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: Obstacle Detection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, 
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 4),
                      Text(value, 
                          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
class ObstacleDetectionScreen extends StatefulWidget {
  final double obstacleDistance;
  final VoidCallback onNext;

  const ObstacleDetectionScreen({
    Key? key,
    required this.obstacleDistance,
    required this.onNext,
  }) : super(key: key);

  @override
  _ObstacleDetectionScreenState createState() => _ObstacleDetectionScreenState();
}

class _ObstacleDetectionScreenState extends State<ObstacleDetectionScreen> with SingleTickerProviderStateMixin {
  late Timer _sensorUpdateTimer;
  double _obstacleDistance = 500.0;
  bool _obstacleDetected = false;
  double _sensorAngle = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize with REAL data from Firebase
    _obstacleDistance = widget.obstacleDistance;
    _obstacleDetected = _obstacleDistance < 200;
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    // Update with real-time data from parent
    _sensorUpdateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _updateSensorData();
        });
      }
    });
  }

  void _updateSensorData() {
    // Use REAL data from Firebase
    _obstacleDistance = widget.obstacleDistance;
    _obstacleDetected = _obstacleDistance < 200;
    
    // Simulate sensor angle (not in Firebase)
    final random = Random();
    _sensorAngle = (-45 + random.nextDouble() * 90).clamp(-45, 45);
  }

  @override
  void dispose() {
    _sensorUpdateTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _getObstacleStatus() {
    if (_obstacleDistance < 100) return 'CRITICAL';
    if (_obstacleDistance < 200) return 'WARNING';
    return 'CLEAR';
  }

  Color _getStatusColor() {
    if (_obstacleDistance < 100) return Colors.redAccent;
    if (_obstacleDistance < 200) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String _getObstacleDirection() {
    if (_sensorAngle < -15) return '${_sensorAngle.abs().toStringAsFixed(0)}° PORT';
    if (_sensorAngle > 15) return '${_sensorAngle.abs().toStringAsFixed(0)}° STARBOARD';
    return 'DEAD AHEAD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Icon(Icons.sensors, size: 40, color: Colors.white),
                          );
                        },
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ULTRASONIC SENSOR SYSTEM', 
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Obstacle Detection', 
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _buildSensorStatus('FRONT', Icons.navigation, true),
                      SizedBox(width: 15),
                      _buildSensorStatus('PORT', Icons.rotate_left, true),
                      SizedBox(width: 15),
                      _buildSensorStatus('STBD', Icons.rotate_right, true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Real-time Distance Visualization
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'REAL-TIME DISTANCE SENSING',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Distance Meter
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.greenAccent.withOpacity(0.1),
                                    Colors.orangeAccent.withOpacity(0.1),
                                    Colors.redAccent.withOpacity(0.1)
                                  ],
                                  stops: [0.6, 0.8, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            
                            // Distance indicator
                            AnimatedPositioned(
                              duration: Duration(milliseconds: 300),
                              left: (_obstacleDistance - 50) / 450 * (MediaQuery.of(context).size.width - 60),
                              child: Column(
                                children: [
                                  Icon(Icons.arrow_upward, color: _getStatusColor(), size: 30),
                                  Text(
                                    '${_obstacleDistance.toStringAsFixed(0)}cm',
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Scale markers
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('50cm', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('200cm', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('500cm', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Status Indicator
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _obstacleDetected ? Icons.warning : Icons.check_circle,
                                color: _getStatusColor(),
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getObstacleStatus(),
                                    style: TextStyle(
                                      color: _getStatusColor(),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _obstacleDetected ? 'OBSTACLE DETECTED' : 'PATH CLEAR',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Sensor Data Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildDataCard('Distance', '${_obstacleDistance.toStringAsFixed(0)} cm', 
                          Icons.social_distance, _getStatusColor()),
                      _buildDataCard('Direction', _getObstacleDirection(), 
                          Icons.compass_calibration, Colors.blueAccent),
                      _buildDataCard('Sensor Angle', '${_sensorAngle.toStringAsFixed(0)}°', 
                          Icons.architecture, Colors.purpleAccent),
                      _buildDataCard('Update Rate', '500 ms', 
                          Icons.update, Colors.greenAccent),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Navigation Status
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'NAVIGATION STATUS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNavStatus('Speed', '2.5 m/s', Icons.speed, Colors.greenAccent),
                            _buildNavStatus('Course', 'N 45° E', Icons.explore, Colors.blueAccent),
                            _buildNavStatus('Auto-Pilot', 'ACTIVE', Icons.autorenew, Colors.greenAccent),
                          ],
                        ),
                        SizedBox(height: 15),
                        Text(
                          _obstacleDetected 
                              ? '⚠️ Taking evasive action - Adjusting course to avoid obstacle'
                              : '✅ Maintaining optimal course - No obstacles detected',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _obstacleDetected ? Colors.orangeAccent : Colors.greenAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Next Button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: Icon(Icons.arrow_forward, size: 20),
                label: Text('NEXT: FLOOD RISK ALERT SYSTEM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorStatus(String label, IconData icon, bool active) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: active ? Colors.greenAccent : Colors.redAccent),
          ),
          child: Icon(icon, size: 16, color: active ? Colors.greenAccent : Colors.redAccent),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildDataCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value, 
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNavStatus(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

// Continue with other screens...

class FloodRiskAlertScreen extends StatefulWidget {
  final double waterLevel;
  final VoidCallback onNext;

  const FloodRiskAlertScreen({Key? key, required this.waterLevel, required this.onNext}) : super(key: key);

  @override
  _FloodRiskAlertScreenState createState() => _FloodRiskAlertScreenState();
}

class _FloodRiskAlertScreenState extends State<FloodRiskAlertScreen> with SingleTickerProviderStateMixin {
  late Timer _dataUpdateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Real-time data simulation
  double _currentWaterLevel = 0.0;
  double _rainfallIntensity = 0.0;
  double _soilMoisture = 0.0;
  double _riverFlowRate = 0.0;
  bool _isAlertActive = false;
  List<Map<String, dynamic>> _recentAlerts = [];
  List<Map<String, dynamic>> _evacuationZones = [];

  @override
  void initState() {
    super.initState();
    _currentWaterLevel = widget.waterLevel;
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _initializeData();
    _startDataUpdates();
  }

  void _initializeData() {
    _recentAlerts = [
      {
        'type': 'GLOF Warning',
        'message': 'Potential glacial lake outburst detected in Sector 4B',
        'time': '10:23 AM',
        'severity': 'High',
        'verified': true
      },
      {
        'type': 'Heavy Rainfall',
        'message': 'Intense rainfall expected in next 6 hours',
        'time': '09:45 AM',
        'severity': 'Medium',
        'verified': true
      },
      {
        'type': 'River Monitoring',
        'message': 'River levels rising rapidly in eastern valley',
        'time': '08:30 AM',
        'severity': 'High',
        'verified': true
      }
    ];

    _evacuationZones = [
      {'name': 'Zone A - High Ground', 'capacity': '500 people', 'distance': '2.3 km', 'status': 'Available'},
      {'name': 'Zone B - Community Center', 'capacity': '300 people', 'distance': '1.8 km', 'status': 'Available'},
      {'name': 'Zone C - School Campus', 'capacity': '700 people', 'distance': '3.1 km', 'status': 'Full'},
    ];
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _updateRealTimeData();
        });
      }
    });
  }

  void _updateRealTimeData() {
    final random = Random();
    _currentWaterLevel = (widget.waterLevel + random.nextDouble() * 10 - 5).clamp(0, 100);
    _rainfallIntensity = random.nextDouble() * 100;
    _soilMoisture = random.nextDouble() * 100;
    _riverFlowRate = random.nextDouble() * 500;
    _isAlertActive = _currentWaterLevel > 70;
  }

  String _getRiskLevel() {
    if (_currentWaterLevel > 80) return 'CRITICAL';
    if (_currentWaterLevel > 60) return 'HIGH';
    if (_currentWaterLevel > 40) return 'MEDIUM';
    return 'LOW';
  }

  Color _getRiskColor() {
    if (_currentWaterLevel > 80) return Colors.redAccent;
    if (_currentWaterLevel > 60) return Colors.orangeAccent;
    if (_currentWaterLevel > 40) return Colors.yellowAccent;
    return Colors.greenAccent;
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'High': return Colors.redAccent;
      case 'Medium': return Colors.orangeAccent;
      case 'Low': return Colors.greenAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Column(
        children: [
          // Enhanced Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Icon(Icons.warning_amber, size: 40, color: Colors.white),
                          );
                        },
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GLOF RISK MONITORING', 
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Flood Risk Alert System', 
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatusIndicator('AI Monitoring', Icons.psychology, true),
                      SizedBox(width: 15),
                      _buildStatusIndicator('Sensors', Icons.sensors, true),
                      SizedBox(width: 15),
                      _buildStatusIndicator('Network', Icons.cloud, true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main Risk Indicator Card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getRiskColor().withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _getRiskColor().withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'REAL-TIME FLOOD RISK ASSESSMENT',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        // Animated Water Level Gauge
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: _currentWaterLevel / 100,
                                backgroundColor: Colors.white10,
                                color: _getRiskColor(),
                                strokeWidth: 12,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_currentWaterLevel.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _getRiskColor(),
                                  ),
                                ),
                                Text(
                                  'WATER LEVEL',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Risk Status
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _getRiskColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _getRiskColor().withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isAlertActive ? Icons.warning : Icons.check_circle,
                                color: _getRiskColor(),
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getRiskLevel(),
                                    style: TextStyle(
                                      color: _getRiskColor(),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _isAlertActive ? 'ALERT ACTIVE' : 'SYSTEM NORMAL',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Risk Description
                        Text(
                          _getRiskDescription(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Environmental Parameters Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildParameterCard('Rainfall', '${_rainfallIntensity.toStringAsFixed(1)} mm/h', 
                          Icons.cloud, Colors.blueAccent),
                      _buildParameterCard('Soil Moisture', '${_soilMoisture.toStringAsFixed(1)}%', 
                          Icons.grass, Colors.greenAccent),
                      _buildParameterCard('River Flow', '${_riverFlowRate.toStringAsFixed(0)} m³/s', 
                          Icons.waves, Colors.cyanAccent),
                      _buildParameterCard('Risk Probability', '${(_currentWaterLevel * 0.8).toStringAsFixed(1)}%', 
                          Icons.analytics, _getRiskColor()),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Recent Alerts Section
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT ALERTS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text('${_recentAlerts.length} Active', 
                                  style: TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: Colors.redAccent,
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        ..._recentAlerts.map((alert) => _buildAlertCard(alert)).toList(),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Evacuation Zones
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEAREST EVACUATION ZONES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        ..._evacuationZones.map((zone) => _buildEvacuationZoneCard(zone)).toList(),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // EMERGENCY ACTIONS Section - Updated to match screenshot
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY ACTIONS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 15),
                        
                        _buildEmergencyAction('Alert Adherents', Icons.notifications_active, Colors.blueAccent, () {
                          _showEmergencyDialog(context);
                        }),
                        
                        SizedBox(height: 12),
                        
                        _buildEmergencyAction('Commandry Alert', Icons.emergency_share, Colors.orangeAccent, () {
                          _sendCommunityAlert();
                        }),
                        
                        SizedBox(height: 12),
                        
                        _buildEmergencyAction('Medical Emergency', Icons.health_and_safety, Colors.redAccent, () {
                          _showEvacuationPlan(context);
                        }),
                        
                        SizedBox(height: 12),
                        
                        _buildEmergencyAction('Resource Mobilization', Icons.inventory, Colors.greenAccent, () {
                          _requestResources();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Next Button Container
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: Icon(Icons.arrow_forward, size: 20),
                label: Text('NEXT: SMART CHARGING SYSTEM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isAlertActive ? FloatingActionButton(
        onPressed: () {
          _broadcastEmergencyAlert();
        },
        backgroundColor: Colors.redAccent,
        child: Icon(Icons.emergency_share),
        tooltip: 'Broadcast Emergency Alert',
      ) : null,
    );
  }

  Widget _buildStatusIndicator(String label, IconData icon, bool active) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: active ? Colors.greenAccent : Colors.redAccent),
          ),
          child: Icon(icon, size: 16, color: active ? Colors.greenAccent : Colors.redAccent),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildParameterCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(value, 
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(title, 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSeverityColor(alert['severity']).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _getSeverityColor(alert['severity']).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: _getSeverityColor(alert['severity']), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert['type'], 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(alert['message'], 
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(height: 4),
                Text(alert['time'], 
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Chip(
            label: Text(alert['severity'], 
                style: TextStyle(color: Colors.white, fontSize: 10)),
            backgroundColor: _getSeverityColor(alert['severity']),
          ),
        ],
      ),
    );
  }

  Widget _buildEvacuationZoneCard(Map<String, dynamic> zone) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.place, color: Colors.blueAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone['name'], 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Capacity: ${zone['capacity']} • Distance: ${zone['distance']}', 
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Chip(
            label: Text(zone['status'], 
                style: TextStyle(color: Colors.white, fontSize: 10)),
            backgroundColor: zone['status'] == 'Available' ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                _getOperationText(title),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOperationText(String title) {
    switch (title) {
      case 'Alert Adherents':
        return 'Operation Line';
      case 'Commandry Alert':
        return 'Operation Request';
      case 'Medical Emergency':
        return 'Medical Support Line';
      case 'Resource Mobilization':
        return 'Resource Operation';
      default:
        return 'Operation Active';
    }
  }

  String _getRiskDescription() {
    if (_currentWaterLevel > 80) {
      return '🚨 CRITICAL: Immediate evacuation recommended. Contact emergency services. High probability of GLOF event.';
    } else if (_currentWaterLevel > 60) {
      return '⚠️ HIGH: Monitor closely. Prepare evacuation plans. Alert community members.';
    } else if (_currentWaterLevel > 40) {
      return '🔶 MEDIUM: Stay alert. Review emergency procedures. Monitor weather updates.';
    } else {
      return '✅ LOW: Normal conditions. Continue regular monitoring. System operational.';
    }
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E2C),
          title: Text('Emergency Alert Authorities', 
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send emergency alert to disaster management teams?',
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Priority: HIGH', 
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Emergency alert sent to authorities'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  void _showEvacuationPlan(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Evacuation Plan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 15),
                ..._evacuationZones.map((zone) => ListTile(
                  leading: Icon(Icons.place, color: Colors.blueAccent),
                  title: Text(zone['name'], style: TextStyle(color: Colors.white)),
                  subtitle: Text('${zone['distance']} • ${zone['status']}', style: TextStyle(color: Colors.white70)),
                  trailing: zone['status'] == 'Available' 
                      ? Icon(Icons.check_circle, color: Colors.green) 
                      : Icon(Icons.warning, color: Colors.orange),
                )).toList(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendCommunityAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Community alert broadcasted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _requestResources() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resource request submitted to disaster management'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _broadcastEmergencyAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 EMERGENCY ALERT: Flood risk critical - Evacuation advised'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _dataUpdateTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
// Implement remaining screens with similar professional structure...


class SmartChargingScreen extends StatelessWidget {
  final double batteryLevel;
  final double solarVoltage;
  final VoidCallback onNext;

  const SmartChargingScreen({Key? key, required this.batteryLevel, required this.solarVoltage, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Smart Charging System', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Solar-powered battery management and monitoring',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Charging Cards Section - Each in separate row
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Battery Level - Single row
                    _buildChargeCard(
                      'Battery Level', 
                      '${batteryLevel.toStringAsFixed(1)}%', 
                      Icons.battery_std, 
                      _getBatteryColor(batteryLevel),
                      'Current charge level'
                    ),
                    SizedBox(height: 15),
                    
                    // Solar Voltage - Single row
                    _buildChargeCard(
                      'Solar Voltage', 
                      '${solarVoltage.toStringAsFixed(1)}V', 
                      Icons.solar_power, 
                      Colors.yellowAccent,
                      'Current solar input'
                    ),
                    SizedBox(height: 15),
                    
                    // Charging Status - Single row
                    _buildChargeCard(
                      'Charging Status', 
                      batteryLevel < 95 ? 'ACTIVE' : 'FULL', 
                      Icons.power, 
                      batteryLevel < 95 ? Colors.greenAccent : Colors.blueAccent,
                      batteryLevel < 95 ? 'Charging in progress' : 'Battery fully charged'
                    ),
                    SizedBox(height: 15),
                    
                    // Energy Today - Single row
                    _buildChargeCard(
                      'Energy Today', 
                      '${(batteryLevel * 0.5).toStringAsFixed(1)} kWh', 
                      Icons.energy_savings_leaf, 
                      Colors.tealAccent,
                      'Total energy generated'
                    ),
                    SizedBox(height: 15),
                    
                    // Charging Rate - Single row
                    _buildChargeCard(
                      'Charging Rate', 
                      '${(solarVoltage * 2.5).toStringAsFixed(1)} W', 
                      Icons.speed, 
                      Colors.orangeAccent,
                      'Current charging power'
                    ),
                    SizedBox(height: 15),
                    
                    // Estimated Time - Single row
                    _buildChargeCard(
                      'Estimated Time', 
                      batteryLevel < 95 ? '${((100 - batteryLevel) / 5).toStringAsFixed(0)}h' : 'FULL', 
                      Icons.timer, 
                      Colors.purpleAccent,
                      batteryLevel < 95 ? 'Time to full charge' : 'Charging complete'
                    ),
                    SizedBox(height: 15),
                    
                    // Battery Health Card - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.health_and_safety, color: Colors.greenAccent),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Battery Health', 
                                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                                      Text('${_getBatteryHealth(batteryLevel)}', 
                                          style: TextStyle(color: _getBatteryHealthColor(batteryLevel), fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: batteryLevel / 100,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(_getBatteryColor(batteryLevel)),
                              minHeight: 6,
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0%', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                Text('100%', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Solar Efficiency Card - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.safety_check, color: Colors.yellowAccent),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Solar Efficiency', 
                                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                                      Text('${(solarVoltage / 24 * 100).toStringAsFixed(1)}%', 
                                          style: TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text('Optimal performance maintained',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Refresh', Colors.blueAccent),
                    _buildActionButton(Icons.offline_bolt, 'Power', Colors.greenAccent),
                    _buildActionButton(Icons.settings, 'Settings', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: AI Vision'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(double level) {
    if (level > 70) return Colors.greenAccent;
    if (level > 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getBatteryHealthColor(double level) {
    if (level > 80) return Colors.greenAccent;
    if (level > 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getBatteryHealth(double level) {
    if (level > 80) return 'Excellent';
    if (level > 60) return 'Good';
    if (level > 40) return 'Fair';
    if (level > 20) return 'Low';
    return 'Critical';
  }

  Widget _buildChargeCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, 
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 4),
                      Text(value, 
                          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
class AIVisionScreen extends StatefulWidget {
  final VoidCallback onNext;

  const AIVisionScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  _AIVisionScreenState createState() => _AIVisionScreenState();
}

class _AIVisionScreenState extends State<AIVisionScreen> {
  bool _isStreaming = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('AI-Powered Vision', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (_isStreaming) ..._buildDetectionOverlays(),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(_isStreaming ? Icons.videocam : Icons.videocam_off, 
                                    color: Colors.white, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  _isStreaming ? 'LIVE' : 'OFFLINE',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _isStreaming = !_isStreaming),
                        icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                        label: Text(_isStreaming ? 'Stop Stream' : 'Start Stream'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isStreaming ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Image captured and saved to database'),
                              backgroundColor: Colors.greenAccent,
                            ),
                          );
                        },
                        icon: Icon(Icons.photo_camera),
                        label: Text('Capture'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildDetectionItem('Plastic Waste', '92%', 'Top Left'),
                        _buildDetectionItem('Hyacinth', '78%', 'Center'),
                        _buildDetectionItem('Organic Matter', '65%', 'Bottom Right'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: widget.onNext,
              icon: Icon(Icons.arrow_forward),
              label: Text('Next: Gas Sensing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetectionOverlays() {
    return [
      Positioned(
        top: 40,
        left: 30,
        child: _buildDetectionBox('Plastic', 0.92),
      ),
      Positioned(
        top: 100,
        left: 150,
        child: _buildDetectionBox('Hyacinth', 0.78),
      ),
      Positioned(
        top: 160,
        left: 80,
        child: _buildDetectionBox('Organic', 0.65),
      ),
    ];
  }

  Widget _buildDetectionBox(String label, double confidence) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.greenAccent, width: 2),
        borderRadius: BorderRadius.circular(6),
        color: Colors.black54,
      ),
      child: Text('$label ${(confidence * 100).toInt()}%', 
          style: TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _buildDetectionItem(String label, String confidence, String position) {
    return Card(
      color: Color(0xFF1E1E2C),
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(label, style: TextStyle(color: Colors.white)),
        subtitle: Text('Position: $position', style: TextStyle(color: Colors.white70)),
        trailing: Chip(
          label: Text(confidence, style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
        ),
      ),
    );
  }
}

// Implement remaining screens...
class GasSensingScreen extends StatelessWidget {
  final VoidCallback onNext;

  const GasSensingScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.air, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Gas Sensing Technology', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Real-time air quality and gas level monitoring',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Gas Cards Section - Each in separate row
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // CO₂ Levels - Single row
                    _buildGasCard(
                      'CO₂ Levels', 
                      '412 ppm', 
                      Icons.co2, 
                      Colors.greenAccent,
                      'Safe',
                      'Carbon dioxide concentration'
                    ),
                    SizedBox(height: 15),
                    
                    // Methane - Single row
                    _buildGasCard(
                      'Methane', 
                      '0.2%', 
                      Icons.local_fire_department, 
                      Colors.orangeAccent,
                      'Low',
                      'Methane gas levels'
                    ),
                    SizedBox(height: 15),
                    
                    // Oxygen - Single row
                    _buildGasCard(
                      'Oxygen', 
                      '20.9%', 
                      Icons.air, 
                      Colors.blueAccent,
                      'Normal',
                      'Oxygen concentration'
                    ),
                    SizedBox(height: 15),
                    
                    // Air Quality - Single row
                    _buildGasCard(
                      'Air Quality', 
                      'Good', 
                      Icons.health_and_safety, 
                      Colors.tealAccent,
                      'Excellent',
                      'Overall air quality index'
                    ),
                    SizedBox(height: 15),
                    
                    // Temperature - Single row
                    _buildGasCard(
                      'Temperature', 
                      '28.5°C', 
                      Icons.thermostat, 
                      Colors.redAccent,
                      'Normal',
                      'Ambient temperature'
                    ),
                    SizedBox(height: 15),
                    
                    // Humidity - Single row
                    _buildGasCard(
                      'Humidity', 
                      '65%', 
                      Icons.water_drop, 
                      Colors.purpleAccent,
                      'Comfortable',
                      'Relative humidity level'
                    ),
                    SizedBox(height: 15),
                    
                    // Air Quality Index Card - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.analytics, color: Colors.tealAccent),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Air Quality Index', 
                                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                                      Text('42 - Good', 
                                          style: TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: 0.42,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                              minHeight: 6,
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0-50 Good', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text('51-100 Moderate', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text('101+ Poor', style: TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Refresh', Colors.blueAccent),
                    _buildActionButton(Icons.history, 'History', Colors.greenAccent),
                    _buildActionButton(Icons.warning, 'Alerts', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: PH Testing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGasCard(String gas, String value, IconData icon, Color color, String status, String subtitle) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gas, 
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 4),
                      Text(value, 
                          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, 
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
// Continue with PH Testing, Turbidity, TDS, Eco-Disposal, etc.
class PHTestingScreen extends StatelessWidget {
  final double phLevel;
  final VoidCallback onNext;

  const PHTestingScreen({Key? key, required this.phLevel, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = phLevel < 6.5 ? 'Acidic' : phLevel > 8.5 ? 'Alkaline' : 'Optimal';
    final color = phLevel < 6.5 ? Colors.redAccent : phLevel > 8.5 ? Colors.orangeAccent : Colors.greenAccent;
    
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.science, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('PH Level Testing', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Water acidity/alkalinity measurement',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // PH Content Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Main PH Display - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Column(
                          children: [
                            Text(
                              'CURRENT PH LEVEL',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              phLevel.toStringAsFixed(1),
                              style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: color),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'STATUS: $status',
                                style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // PH Scale - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('PH Scale Reference', 
                                style: TextStyle(color: Colors.white70, fontSize: 16)),
                            SizedBox(height: 15),
                            Container(
                              width: double.infinity,
                              height: 30,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red, Colors.green, Colors.orange],
                                  stops: [0.0, 0.5, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0 Acidic', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('7 Neutral', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('14 Alkaline', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Water Quality Metrics - Single rows
                    _buildQualityCard('Water Purity', '98%', Icons.clean_hands, Colors.blueAccent),
                    SizedBox(height: 15),
                    _buildQualityCard('Contaminants', '2 ppm', Icons.dangerous, Colors.orangeAccent),
                    SizedBox(height: 15),
                    _buildQualityCard('Recommendation', 'Safe', Icons.recommend, Colors.greenAccent),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Retest', Colors.blueAccent),
                    _buildActionButton(Icons.save, 'Save', Colors.greenAccent),
                    _buildActionButton(Icons.share, 'Report', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: Turbidity Testing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// Implement remaining screens with similar structure...
class TurbidityTestingScreen extends StatelessWidget {
  final double turbidity;
  final VoidCallback onNext;

  const TurbidityTestingScreen({Key? key, required this.turbidity, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = turbidity > 40 ? 'Poor' : turbidity > 20 ? 'Moderate' : 'Good';
    final color = turbidity > 40 ? Colors.redAccent : turbidity > 20 ? Colors.orangeAccent : Colors.greenAccent;
    
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.opacity, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Turbidity Testing', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Water clarity and particle measurement',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Turbidity Content Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Main Turbidity Display - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Column(
                          children: [
                            Text(
                              'TURBIDITY LEVEL',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '${turbidity.toStringAsFixed(1)} NTU',
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'WATER CLARITY: $status',
                                style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Turbidity Scale - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Turbidity Scale', 
                                style: TextStyle(color: Colors.white70, fontSize: 16)),
                            SizedBox(height: 15),
                            LinearProgressIndicator(
                              value: turbidity / 100,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 20,
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text('0 NTU', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Crystal', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('40 NTU', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Moderate', style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('100 NTU', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Cloudy', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Water Quality Metrics - Single rows
                    _buildQualityCard('Particle Count', '${(turbidity * 10).toStringAsFixed(0)}/mL', Icons.grain, Colors.blueAccent),
                    SizedBox(height: 15),
                    _buildQualityCard('Filter Efficiency', '${(100 - turbidity).toStringAsFixed(0)}%', Icons.filter_alt, Colors.tealAccent),
                    SizedBox(height: 15),
                    _buildQualityCard('Visibility', turbidity < 10 ? 'Excellent' : turbidity < 30 ? 'Good' : 'Poor', 
                        Icons.visibility, turbidity < 10 ? Colors.greenAccent : turbidity < 30 ? Colors.orangeAccent : Colors.redAccent),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Retest', Colors.blueAccent),
                    _buildActionButton(Icons.photo, 'Capture', Colors.greenAccent),
                    _buildActionButton(Icons.analytics, 'Trends', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: TDS Testing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}class TDSTestingScreen extends StatelessWidget {
  final double tds;
  final VoidCallback onNext;

  const TDSTestingScreen({Key? key, required this.tds, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = tds > 1000 ? 'Poor' : tds > 500 ? 'Moderate' : 'Good';
    final color = tds > 1000 ? Colors.redAccent : tds > 500 ? Colors.orangeAccent : Colors.greenAccent;
    
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.water, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('TDS Testing', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Total Dissolved Solids measurement',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // TDS Content Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Main TDS Display - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Column(
                          children: [
                            Text(
                              'TOTAL DISSOLVED SOLIDS',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '${tds.toStringAsFixed(0)} ppm',
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
                            ),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'WATER QUALITY: $status',
                                style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // TDS Scale - Single row
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('TDS Quality Scale', 
                                style: TextStyle(color: Colors.white70, fontSize: 16)),
                            SizedBox(height: 15),
                            LinearProgressIndicator(
                              value: tds / 2000,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 20,
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    Text('0-300', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Excellent', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('300-600', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Good', style: TextStyle(color: Colors.blueAccent, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('600-900', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Fair', style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('900+', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text('Poor', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Water Quality Metrics - Single rows
                    _buildQualityCard('Mineral Content', '${(tds * 0.7).toStringAsFixed(0)} ppm', Icons.eco, Colors.tealAccent),
                    SizedBox(height: 15),
                    _buildQualityCard('Purity Level', '${(100 - (tds/20)).toStringAsFixed(1)}%', Icons.clean_hands, Colors.blueAccent),
                    SizedBox(height: 15),
                    _buildQualityCard('Drinkability', tds < 600 ? 'Safe' : 'Not Recommended', 
                        Icons.local_drink, tds < 600 ? Colors.greenAccent : Colors.redAccent),
                    SizedBox(height: 15),
                    
                    // Recommendation Card
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.recommend, color: color),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Recommendation', 
                                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  Text(
                                    tds < 300 ? 'Excellent for drinking' : 
                                    tds < 600 ? 'Good for drinking' : 
                                    'Consider filtration',
                                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Retest', Colors.blueAccent),
                    _buildActionButton(Icons.water_drop, 'Sample', Colors.greenAccent),
                    _buildActionButton(Icons.summarize, 'Report', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: Eco-Disposal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
class EcoDisposalMethodsScreen extends StatelessWidget {
  final VoidCallback onNext;

  const EcoDisposalMethodsScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F111C),
      body: Column(
        children: [
          // Enhanced Header Section
          Container(
            padding: EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.recycling, size: 32, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Eco-Disposal Methods', 
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Sustainable waste conversion technologies',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Text('ACTIVE', 
                          style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                _buildEnvironmentalImpact(),
              ],
            ),
          ),
          
          // Main Content Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Method Cards Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildMethodCard(
                          'Biogas Conversion',
                          '12.5 kg/day',
                          Icons.energy_savings_leaf,
                          Colors.greenAccent,
                          'Methane production from organic waste',
                          85,
                        ),
                        _buildMethodCard(
                          'Organic Fertilizer',
                          '8.2 kg/day',
                          Icons.eco,
                          Colors.tealAccent,
                          'Nutrient-rich compost production',
                          92,
                        ),
                        _buildMethodCard(
                          'Energy Generation',
                          '5.7 kWh/day',
                          Icons.bolt,
                          Colors.orangeAccent,
                          'Thermal and electrical energy',
                          78,
                        ),
                        _buildMethodCard(
                          'Carbon Credits',
                          '45.6 earned',
                          Icons.credit_card,
                          Colors.purpleAccent,
                          'Carbon offset certification',
                          95,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Efficiency Metrics Card
                    _buildEfficiencyCard(),
                    SizedBox(height: 20),
                    
                    // Environmental Benefits Card
                    _buildBenefitsCard(),
                    SizedBox(height: 20),
                    
                    // Process Flow Card
                    _buildProcessFlowCard(),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Panel
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.analytics, 'Analytics', Colors.blueAccent),
                    _buildActionButton(Icons.schedule, 'Schedule', Colors.greenAccent),
                    _buildActionButton(Icons.settings, 'Configure', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward, size: 20),
                  label: Text('Next: Predictive Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpact() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildImpactStat('CO₂ Reduced', '2.4t', Icons.cloud_off, Colors.greenAccent),
          _buildImpactStat('Energy Saved', '1.8MWh', Icons.energy_savings_leaf, Colors.blueAccent),
          _buildImpactStat('Water Saved', '45kL', Icons.water_drop, Colors.tealAccent),
        ],
      ),
    );
  }

  Widget _buildImpactStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildMethodCard(String title, String value, IconData icon, Color color, String description, int efficiency) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$efficiency%', 
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(title, 
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(value, 
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(description,
                style: TextStyle(color: Colors.white54, fontSize: 10)),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: efficiency / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text('System Efficiency', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEfficiencyMetric('Conversion Rate', '89.2%', Colors.greenAccent),
                _buildEfficiencyMetric('Waste Reduction', '94.7%', Colors.blueAccent),
                _buildEfficiencyMetric('Energy Output', '82.3%', Colors.orangeAccent),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('All systems operating at optimal efficiency',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.tealAccent, size: 20),
                SizedBox(width: 8),
                Text('Environmental Benefits', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBenefitChip('Zero Waste', Icons.all_inclusive, Colors.greenAccent),
                _buildBenefitChip('Carbon Neutral', Icons.co2, Colors.blueAccent),
                _buildBenefitChip('Renewable', Icons.autorenew, Colors.orangeAccent),
                _buildBenefitChip('Sustainable', Icons.psychology, Colors.purpleAccent),
                _buildBenefitChip('Circular', Icons.cached, Colors.tealAccent),
                _buildBenefitChip('Green Tech', Icons.engineering, Colors.yellowAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildProcessFlowCard() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: Colors.purpleAccent, size: 20),
                SizedBox(width: 8),
                Text('Disposal Process Flow', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 12),
            _buildProcessStep('Collection', 'Waste gathering', Icons.cleaning_services, Colors.blueAccent),
            _buildProcessStep('Segregation', 'Material separation', Icons.filter_alt, Colors.greenAccent),
            _buildProcessStep('Processing', 'Conversion treatment', Icons.settings, Colors.orangeAccent),
            _buildProcessStep('Output', 'Final products', Icons.output, Colors.purpleAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessStep(String title, String description, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
                Text(description, style: TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, size: 16, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

// Continue with Predictive Analytics, Fleet Management, Citizen Portal...
class PredictiveAnalyticsScreen extends StatelessWidget {
  final VoidCallback onNext;

  const PredictiveAnalyticsScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Predictive Analytics', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('AI-powered forecasts for optimal operations',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Analytics Cards Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Flood Risk Card
                    _buildAnalyticsCard(
                      'Flood Risk',
                      'Next 48 hours',
                      Icons.water_damage,
                      Colors.blueAccent,
                      'Low (15%)',
                      0.15,
                      _buildRiskIndicator(0.15),
                    ),
                    SizedBox(height: 15),
                    
                    // Hyacinth Growth Card
                    _buildAnalyticsCard(
                      'Hyacinth Growth',
                      'Next 48 hours',
                      Icons.grass,
                      Colors.greenAccent,
                      'High (85%)',
                      0.85,
                      _buildRiskIndicator(0.85),
                    ),
                    SizedBox(height: 15),
                    
                    // Water Quality Card
                    _buildAnalyticsCard(
                      'Water Quality',
                      'Next 48 hours',
                      Icons.water,
                      Colors.tealAccent,
                      'Improving',
                      0.65,
                      _buildTrendIndicator(true),
                    ),
                    SizedBox(height: 15),
                    
                    // Maintenance Card
                    _buildAnalyticsCard(
                      'Maintenance',
                      'Next 48 hours',
                      Icons.engineering,
                      Colors.orangeAccent,
                      'Bot #3 Due',
                      0.25,
                      _buildMaintenanceIndicator(),
                    ),
                    SizedBox(height: 15),
                    
                    // Statistics Overview Card
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.bar_chart, color: Colors.purpleAccent),
                                ),
                                SizedBox(width: 15),
                                Text('Risk Overview', 
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 15),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Low Risk', '2', Colors.greenAccent),
                                _buildStatItem('Medium', '1', Colors.orangeAccent),
                                _buildStatItem('High', '1', Colors.redAccent),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // AI Recommendations Card
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.lightbulb, color: Colors.yellowAccent),
                                ),
                                SizedBox(width: 15),
                                Text('AI Recommendations', 
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 10),
                            
                            _buildRecommendation(
                              'Deploy Bot #3 for maintenance',
                              Icons.build,
                              Colors.blueAccent,
                            ),
                            SizedBox(height: 8),
                            
                            _buildRecommendation(
                              'Monitor hyacinth growth areas',
                              Icons.visibility,
                              Colors.greenAccent,
                            ),
                            SizedBox(height: 8),
                            
                            _buildRecommendation(
                              'Prepare flood prevention measures',
                              Icons.security,
                              Colors.orangeAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.refresh, 'Refresh', Colors.blueAccent),
                    _buildActionButton(Icons.download, 'Export', Colors.greenAccent),
                    _buildActionButton(Icons.notifications, 'Alerts', Colors.orangeAccent),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: Fleet Management'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String timeframe, IconData icon, Color color, 
                            String prediction, double value, Widget indicator) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(timeframe,
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(prediction,
                      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 15),
            indicator,
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('Probability', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('100%', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskIndicator(double value) {
    Color color;
    String status;
    
    if (value < 0.3) {
      color = Colors.greenAccent;
      status = 'LOW RISK';
    } else if (value < 0.7) {
      color = Colors.orangeAccent;
      status = 'MEDIUM RISK';
    } else {
      color = Colors.redAccent;
      status = 'HIGH RISK';
    }
    
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 12),
        SizedBox(width: 8),
        Text(status, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTrendIndicator(bool improving) {
    return Row(
      children: [
        Icon(
          improving ? Icons.trending_up : Icons.trending_down,
          color: improving ? Colors.greenAccent : Colors.redAccent,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          improving ? 'IMPROVING' : 'DETERIORATING',
          style: TextStyle(
            color: improving ? Colors.greenAccent : Colors.redAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceIndicator() {
    return Row(
      children: [
        Icon(Icons.warning, color: Colors.orangeAccent, size: 20),
        SizedBox(width: 8),
        Text('MAINTENANCE REQUIRED', 
            style: TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(value,
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildRecommendation(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
class FleetManagementScreen extends StatelessWidget {
  final VoidCallback onNext;

  const FleetManagementScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bots = List.generate(8, (index) => {
      'name': 'OPTIMUS-${index + 1}',
      'status': ['Active', 'Charging', 'Maintenance'][index % 3],
      'battery': 20 + Random().nextInt(80),
      'zone': ['A', 'B', 'C', 'D'][index % 4],
    });

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_boat, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Fleet Management', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bots.length,
              itemBuilder: (context, index) {
                final bot = bots[index];
                final status = bot['status'] as String;
                final name = bot['name'] as String;
                final battery = bot['battery'] as int;
                final zone = bot['zone'] as String;
                
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Color(0xFF1E1E2C),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status),
                      child: Icon(Icons.engineering, color: Colors.white),
                    ),
                    title: Text(name, style: TextStyle(color: Colors.white)),
                    subtitle: Text('$status • Zone $zone', style: TextStyle(color: Colors.white70)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$battery%', style: TextStyle(color: _getBatteryColor(battery.toDouble()))),
                        SizedBox(height: 4),
                        Container(
                          width: 40,
                          child: LinearProgressIndicator(
                            value: battery / 100,
                            backgroundColor: Colors.white24,
                            color: _getBatteryColor(battery.toDouble()),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(Icons.arrow_forward),
              label: Text('Next: Citizen Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return Colors.greenAccent;
      case 'Charging': return Colors.orangeAccent;
      case 'Maintenance': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Color _getBatteryColor(double level) {
    if (level > 70) return Colors.greenAccent;
    if (level > 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}class CitizenPortalScreen extends StatelessWidget {
  final VoidCallback onNext;

  const CitizenPortalScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 40, color: Colors.white),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Citizen Portal', 
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Community Engagement Platform', 
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMMUNITY SERVICES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Individual Service Containers
                  _buildServiceContainer(
                    'Report Issue', 
                    Icons.report, 
                    Colors.redAccent,
                    'Issue Reporting System',
                    () => _showReportDialog(context)
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildServiceContainer(
                    'Volunteer', 
                    Icons.volunteer_activism, 
                    Colors.greenAccent,
                    'Community Support',
                    () => _showVolunteerDialog(context)
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildServiceContainer(
                    'Live Camera', 
                    Icons.videocam, 
                    Colors.blueAccent,
                    'Live Monitoring Feed',
                    () => _showLiveCamera(context)
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildServiceContainer(
                    'Eco Tips', 
                    Icons.eco, 
                    Colors.tealAccent,
                    'Sustainability Guide',
                    () => _showEcoTips(context)
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildServiceContainer(
                    'Events', 
                    Icons.event, 
                    Colors.orangeAccent,
                    'Community Calendar',
                    () => _showEvents(context)
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildServiceContainer(
                    'Education', 
                    Icons.school, 
                    Colors.purpleAccent,
                    'Learning Resources',
                    () => _showEducation(context)
                  ),
                ],
              ),
            ),
          ),
          
          // Next Button Container
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(Icons.arrow_forward, size: 20),
              label: Text('Next: Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceContainer(String title, IconData icon, Color color, String operationText, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                operationText,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('Report Environmental Issue', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Issue Description', 
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Location', 
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Issue reported successfully!'), 
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _showVolunteerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('Join as Volunteer', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Thank you for your interest! Our team will contact you soon.', 
            style: TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLiveCamera(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Live Camera Feed', 
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 15),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEcoTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('Eco-Friendly Tips', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            '• Reduce plastic usage\n• Proper waste disposal\n• Conserve water\n• Use eco-friendly products\n• Support clean energy',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEvents(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('Upcoming Events', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            '• River Cleanup - Oct 15\n• Eco Workshop - Oct 20\n• Community Planting - Oct 25',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEducation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E2C),
        title: Text('Educational Resources', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'Access our online courses:\n• Water Conservation\n• Waste Management\n• Sustainable Living',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
// Contact and Judges FAQ screens...

class ContactScreen extends StatelessWidget {
  final VoidCallback onNext;

  const ContactScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.3),
                  blurRadius: 15,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.contact_page, size: 40, color: Colors.white),
                  SizedBox(width: 15),
                  Text('Contact Us', 
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTACT INFORMATION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Contact Items - Exact layout from screenshot
                  _buildContactContainer(
                    Icons.phone,
                    '+91 7397463420',
                    '24/7 Support',
                    Colors.greenAccent
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildContactContainer(
                    Icons.email,
                    'optimusx.tech@gmail.com',
                    'Email Support',
                    Colors.blueAccent
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildContactContainer(
                    Icons.location_on,
                    'Chennai, India',
                    'Headquarters',
                    Colors.orangeAccent
                  ),
                  
                  SizedBox(height: 12),
                  
                  _buildContactContainer(
                    Icons.language,
                    'www.optimusx.tech',
                    'Website',
                    Colors.purpleAccent
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Additional Info Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUPPORT HOURS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.yellowAccent, size: 20),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mon-Sun: 24/7',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Always Available',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Next Button Container
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(Icons.arrow_forward, size: 20),
              label: Text('Next: Judges FAQ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactContainer(IconData icon, String value, String label, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class JudgesFAQScreen extends StatelessWidget {
  final VoidCallback onNext;

  const JudgesFAQScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.quiz, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Judges FAQ', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: ListView(
                children: [
                  _buildFAQItem(
                    'How does OPTIMUS-X handle dense hyacinth mats?',
                    'Advanced AI algorithms optimize cutting patterns with dual-conveyor system for continuous operation.'
                  ),
                  _buildFAQItem(
                    'What prevents hyacinth from regrowing?',
                    'Root removal technology combined with AI-powered monitoring prevents regrowth effectively.'
                  ),
                  _buildFAQItem(
                    'How do you ensure aquatic life safety?',
                    'Multiple safety systems: slow-moving blades, object detection, noise reduction, emergency stops.'
                  ),
                  _buildFAQItem(
                    'What is your carbon footprint reduction?',
                    'Solar-powered operation reduces emissions by 65% compared to traditional methods.'
                  ),
                  _buildFAQItem(
                    'How scalable is this solution?',
                    'Modular design allows fleet coordination across multiple water bodies simultaneously.'
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(Icons.arrow_forward),
              label: Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      color: Color(0xFF1E1E2C),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(question, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(answer, style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class LogoutScreen extends StatelessWidget {
  final VoidCallback onLogoutComplete;

  const LogoutScreen({Key? key, required this.onLogoutComplete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), onLogoutComplete);

    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              "Logging Out...",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Thank you for using OPTIMUS-X",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}
class DualConveyorControlScreen extends StatefulWidget {
  final double conveyor1Speed;
  final double conveyor2Speed;
  final bool shredderActive;
  final bool compactorActive;
  final Function(double, double, bool, bool) onSpeedChange;
  final VoidCallback onNext;

  const DualConveyorControlScreen({
    Key? key,
    required this.conveyor1Speed,
    required this.conveyor2Speed,
    required this.shredderActive,
    required this.compactorActive,
    required this.onSpeedChange,
    required this.onNext,
  }) : super(key: key);

  @override
  _DualConveyorControlScreenState createState() => _DualConveyorControlScreenState();
}

class _DualConveyorControlScreenState extends State<DualConveyorControlScreen> {
  late double _conveyor1Speed;
  late double _conveyor2Speed;
  late bool _shredderActive;
  late bool _compactorActive;

  @override
  void initState() {
    super.initState();
    _conveyor1Speed = widget.conveyor1Speed;
    _conveyor2Speed = widget.conveyor2Speed;
    _shredderActive = widget.shredderActive;
    _compactorActive = widget.compactorActive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.conveyor_belt, size: 40, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Dual Conveyor Control', 
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 10),
                Text('Real-time robotic conveyor belt management',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          
          // Control Cards Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Primary Conveyor Card
                    _buildConveyorCard(
                      'Primary Conveyor',
                      'Garbage Processing',
                      _conveyor1Speed,
                      Icons.recycling,
                      Colors.orangeAccent,
                      (value) {
                        setState(() => _conveyor1Speed = value);
                        widget.onSpeedChange(_conveyor1Speed, _conveyor2Speed, _shredderActive, _compactorActive);
                      },
                    ),
                    SizedBox(height: 20),
                    
                    // Secondary Conveyor Card
                    _buildConveyorCard(
                      'Secondary Conveyor',
                      'Hyacinth Processing',
                      _conveyor2Speed,
                      Icons.water,
                      Colors.greenAccent,
                      (value) {
                        setState(() => _conveyor2Speed = value);
                        widget.onSpeedChange(_conveyor1Speed, _conveyor2Speed, _shredderActive, _compactorActive);
                      },
                    ),
                    SizedBox(height: 20),
                    
                    // System Controls Card
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.settings, color: Colors.purpleAccent),
                                ),
                                SizedBox(width: 15),
                                Text('System Controls', 
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Shredder Control
                            _buildSystemControl(
                              'Hyacinth Shredder',
                              'Cuts hyacinth into manageable pieces',
                              _shredderActive,
                              Icons.cut,
                              Colors.redAccent,
                              (value) {
                                setState(() => _shredderActive = value);
                                widget.onSpeedChange(_conveyor1Speed, _conveyor2Speed, _shredderActive, _compactorActive);
                              },
                            ),
                            SizedBox(height: 15),
                            
                            // Compactor Control
                            _buildSystemControl(
                              'Compactor System',
                              'Compresses waste for efficient storage',
                              _compactorActive,
                              Icons.compress,
                              Colors.blueAccent,
                              (value) {
                                setState(() => _compactorActive = value);
                                widget.onSpeedChange(_conveyor1Speed, _conveyor2Speed, _shredderActive, _compactorActive);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Status Overview Card
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.analytics, color: Colors.tealAccent),
                                ),
                                SizedBox(width: 15),
                                Text('System Status', 
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 15),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatusIndicator('Conveyor 1', _conveyor1Speed, Colors.orangeAccent),
                                _buildStatusIndicator('Conveyor 2', _conveyor2Speed, Colors.greenAccent),
                                _buildStatusIndicator('Shredder', _shredderActive ? 1.0 : 0.0, Colors.redAccent),
                                _buildStatusIndicator('Compactor', _compactorActive ? 1.0 : 0.0, Colors.blueAccent),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Performance Metrics Card
                    Card(
                      color: Color(0xFF1E1E2C),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.speed, color: Colors.yellowAccent),
                                ),
                                SizedBox(width: 15),
                                Text('Performance Metrics', 
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 15),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricCard('Throughput', '${(_conveyor1Speed * 50 + _conveyor2Speed * 30).toStringAsFixed(0)} kg/h', Icons.trending_up),
                                _buildMetricCard('Efficiency', '${((_conveyor1Speed + _conveyor2Speed) / 2 * 100).toStringAsFixed(0)}%', Icons.energy_savings_leaf),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.play_arrow, 'Start All', Colors.greenAccent, () {
                      setState(() {
                        _conveyor1Speed = 0.5;
                        _conveyor2Speed = 0.5;
                        _shredderActive = true;
                        _compactorActive = true;
                      });
                      widget.onSpeedChange(_conveyor1Speed, _conveyor2Speed, _shredderActive, _compactorActive);
                    }),
                    _buildActionButton(Icons.stop, 'Stop All', Colors.redAccent, () {
                      setState(() {
                        _conveyor1Speed = 0.0;
                        _conveyor2Speed = 0.0;
                        _shredderActive = false;
                        _compactorActive = false;
                      });
                      widget.onSpeedChange(_conveyor1Speed, _conveyor2Speed, _shredderActive, _compactorActive);
                    }),
                    _buildActionButton(Icons.autorenew, 'Auto', Colors.blueAccent, () {
                      // Auto mode logic
                    }),
                  ],
                ),
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: widget.onNext,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Next: Live Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConveyorCard(String title, String subtitle, double speed, IconData icon, Color color, Function(double) onChanged) {
    return Card(
      color: Color(0xFF1E1E2C),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, 
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Text('${(speed * 100).round()}%', 
                    style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 15),
            Slider(
              value: speed,
              onChanged: onChanged,
              divisions: 20,
              min: 0,
              max: 1,
              label: '${(speed * 100).round()}%',
              activeColor: color,
              inactiveColor: Colors.white24,
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%', style: TextStyle(color: Colors.white54)),
                Text('Speed Control', style: TextStyle(color: Colors.white70)),
                Text('100%', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemControl(String title, String subtitle, bool value, IconData icon, Color color, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: value,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 6,
            ),
            Text('${(value * 100).round()}%', 
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            SizedBox(height: 5),
            Text(title, style: TextStyle(color: Colors.white54, fontSize: 10)),
            Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class HydrobotValveControlsScreen extends StatefulWidget {
  final VoidCallback onNext;

  const HydrobotValveControlsScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  _HydrobotValveControlsScreenState createState() => _HydrobotValveControlsScreenState();
}

class _HydrobotValveControlsScreenState extends State<HydrobotValveControlsScreen> {
  double _valve1Position = 0.0;
  double _valve2Position = 0.0;
  
  ValveStatus _valve1Status = ValveStatus.closed;
  ValveStatus _valve2Status = ValveStatus.closed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(
          'Hydrobot Valve Controls',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF1A237E),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Valve 1 Control Card
                  _buildValveControlCard(
                    'Valve 1',
                    _valve1Position,
                    _valve1Status,
                    (value) => _updateValve1(value),
                    Icons.precision_manufacturing,
                    Colors.blueAccent,
                  ),
                  SizedBox(height: 20),
                  
                  // Valve 2 Control Card
                  _buildValveControlCard(
                    'Valve 2',
                    _valve2Position,
                    _valve2Status,
                    (value) => _updateValve2(value),
                    Icons.precision_manufacturing,
                    Colors.greenAccent,
                  ),
                  SizedBox(height: 20),
                  
                  // System Status Overview
                  _buildSystemStatusCard(),
                ],
              ),
            ),
          ),
          
          // Control Buttons Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E2C),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              children: [
                // Close All Valves Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _closeAllValves,
                    icon: Icon(Icons.dangerous, color: Colors.white),
                    label: Text(
                      'CLOSE ALL VALVES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Next Button
                ElevatedButton.icon(
                  onPressed: widget.onNext,
                  icon: Icon(Icons.arrow_forward, size: 20),
                  label: Text('Next: Live Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValveControlCard(
    String title,
    double position,
    ValveStatus status,
    Function(double) onSliderChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Title and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(status)),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Position Indicator
          Text(
            '${position.round()}% Open',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          
          // Slider Control
          Slider(
            value: position,
            onChanged: onSliderChanged,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${position.round()}%',
            activeColor: color,
            inactiveColor: Colors.white24,
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(color: Colors.white54)),
              Text('Valve Position', style: TextStyle(color: Colors.white70)),
              Text('100%', style: TextStyle(color: Colors.white54)),
            ],
          ),
          SizedBox(height: 20),
          
          // Control Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Open Button
              Expanded(
                child: Container(
                  height: 45,
                  margin: EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _fullyOpenValve(title),
                    icon: Icon(Icons.lock_open, size: 18),
                    label: Text('OPEN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withOpacity(0.9),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Close Button
              Expanded(
                child: Container(
                  height: 45,
                  margin: EdgeInsets.only(left: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _fullyCloseValve(title),
                    icon: Icon(Icons.lock, size: 18),
                    label: Text('CLOSE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM STATUS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusIndicator('Valve 1', _valve1Status, Colors.blueAccent),
              _buildStatusIndicator('Valve 2', _valve2Status, Colors.greenAccent),
            ],
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSystemStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getSystemStatusColor().withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: _getSystemStatusColor(), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getSystemStatusMessage(),
                    style: TextStyle(
                      color: _getSystemStatusColor(),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, ValveStatus status, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _getStatusColor(status), width: 2),
          ),
          child: Center(
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 24,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          _getStatusText(status),
          style: TextStyle(
            color: _getStatusColor(status),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Valve Control Methods
  void _updateValve1(double value) {
    setState(() {
      _valve1Position = value;
      _valve1Status = value == 0 
          ? ValveStatus.closed 
          : value == 100 
            ? ValveStatus.open 
            : ValveStatus.adjusting;
    });
  }

  void _updateValve2(double value) {
    setState(() {
      _valve2Position = value;
      _valve2Status = value == 0 
          ? ValveStatus.closed 
          : value == 100 
            ? ValveStatus.open 
            : ValveStatus.adjusting;
    });
  }

  void _fullyOpenValve(String valveName) {
    setState(() {
      if (valveName == 'Valve 1') {
        _valve1Position = 100;
        _valve1Status = ValveStatus.open;
      } else {
        _valve2Position = 100;
        _valve2Status = ValveStatus.open;
      }
    });
  }

  void _fullyCloseValve(String valveName) {
    setState(() {
      if (valveName == 'Valve 1') {
        _valve1Position = 0;
        _valve1Status = ValveStatus.closed;
      } else {
        _valve2Position = 0;
        _valve2Status = ValveStatus.closed;
      }
    });
  }

  void _closeAllValves() {
    setState(() {
      _valve1Position = 0;
      _valve2Position = 0;
      _valve1Status = ValveStatus.closed;
      _valve2Status = ValveStatus.closed;
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All valves closed successfully'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Helper Methods
  Color _getStatusColor(ValveStatus status) {
    switch (status) {
      case ValveStatus.open:
        return Colors.greenAccent;
      case ValveStatus.closed:
        return Colors.redAccent;
      case ValveStatus.adjusting:
        return Colors.blueAccent;
    }
  }

  String _getStatusText(ValveStatus status) {
    switch (status) {
      case ValveStatus.open:
        return 'OPEN';
      case ValveStatus.closed:
        return 'CLOSED';
      case ValveStatus.adjusting:
        return 'ADJUSTING';
    }
  }

  IconData _getStatusIcon(ValveStatus status) {
    switch (status) {
      case ValveStatus.open:
        return Icons.check_circle;
      case ValveStatus.closed:
        return Icons.cancel;
      case ValveStatus.adjusting:
        return Icons.adjust;
    }
  }

  Color _getSystemStatusColor() {
    if (_valve1Status == ValveStatus.open || _valve2Status == ValveStatus.open) {
      return Colors.greenAccent;
    } else if (_valve1Status == ValveStatus.adjusting || _valve2Status == ValveStatus.adjusting) {
      return Colors.blueAccent;
    } else {
      return Colors.redAccent;
    }
  }

  String _getSystemStatusMessage() {
    if (_valve1Status == ValveStatus.open || _valve2Status == ValveStatus.open) {
      return 'System Active - Valves are open';
    } else if (_valve1Status == ValveStatus.adjusting || _valve2Status == ValveStatus.adjusting) {
      return 'System Adjusting - Valves are being calibrated';
    } else {
      return 'System Standby - All valves are closed';
    }
  }
}

enum ValveStatus {
  open,
  closed,
  adjusting,
}

// Add this to your navigation in the previous screen
// In DualConveyorControlScreen, update the onNext callback:
/*
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HydrobotValveControlsScreen(
          onNext: () {
            // Navigate to next screen after valve controls
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LiveTrashAnalyticsScreen(...)),
            );
          },
        ),
      ),
    );
  },
  
)
*/