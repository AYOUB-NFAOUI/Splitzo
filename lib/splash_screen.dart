import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'const.dart';
import 'ads/multi_ads.dart';
import 'ads/src/utils/log.dart';
import 'input_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasNavigated = false;

  // Durée minimale d'affichage du splash pour une transition fluide
  static const Duration _minSplashDuration = Duration(milliseconds: 2500);
  // Délai de sécurité maximal pour éviter tout blocage si le réseau est indisponible
  static const Duration _maxSplashTimeout = Duration(seconds: 8);

  Timer? _safetyTimeoutTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    // Démarrer la sécurité anti-blocage
    _safetyTimeoutTimer = Timer(_maxSplashTimeout, () {
      Log.log('SplashScreen >> Safety timeout reached, navigating to next screen.');
      _navigateToHome();
    });

    _initializeAdsAndSplash();
  }

  @override
  void dispose() {
    _safetyTimeoutTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeAdsAndSplash() async {
    final startTime = DateTime.now();

    try {
      // 1. Télécharger la configuration des publicités depuis Constants.jsonConfigUrl
      final response = await http
          .get(Uri.parse(Constants.jsonConfigUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        Log.log('SplashScreen >> Ads config downloaded successfully');
        
        // 2. Initialiser le gestionnaire MultiAds
        gAds = MultiAds(response.body);
        await gAds!.init();

        // 3. Charger les publicités en avance (App Open, Interstitiel, etc.)
        await gAds!.loadAds();
      } else {
        Log.log(
            'SplashScreen >> Failed to download ads config: code ${response.statusCode}');
      }
    } catch (e) {
      Log.log('SplashScreen >> Error initializing ads: $e');
    }

    // S'assurer de respecter la durée minimale du Splash
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minSplashDuration) {
      await Future.delayed(_minSplashDuration - elapsed);
    }

    if (!mounted || _hasNavigated) return;

    // 4. Afficher l'annonce Splash (AppOpenAd ou Interstitielle selon la configuration)
    _displaySplashAdAndProceed();
  }

  void _displaySplashAdAndProceed() {
    if (_hasNavigated) return;

    // Vérifier si des annonces sont configurées
    if (gAds != null) {
      final settings = gAds!.adsData.settings;

      // Priorité 1: App Open Ad si configuré
      if (settings.openads.isNotEmpty) {
        Log.log('SplashScreen >> Trying to show AppOpenAd');
        gAds!.openAdsInstance.showAdIfAvailableOpenAds(
          onDismissed: _navigateToHome,
        );

        // Si l'annonce n'est pas prête ou ne s'affiche pas sous 2s, continuer vers l'accueil
        Future.delayed(const Duration(seconds: 2), () {
          if (!isInterShowed && !_hasNavigated) {
            Log.log('SplashScreen >> AppOpenAd not displayed in time, proceeding.');
            _navigateToHome();
          }
        });
        return;
      }

      // Priorité 2: Interstitiel si configuré
      if (settings.inters.isNotEmpty) {
        Log.log('SplashScreen >> Trying to show Interstitial');
        gAds!.interInstance.showInterstitialAd(
          onDismissed: _navigateToHome,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (!isInterShowed && !_hasNavigated) {
            Log.log('SplashScreen >> Interstitial not displayed in time, proceeding.');
            _navigateToHome();
          }
        });
        return;
      }
    }

    // Si aucune pub ou réseau hors-ligne, aller directement sur l'écran principal
    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _safetyTimeoutTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const InputScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryTeal = Color(0xFF1EA896);
    const deepTeal = Color(0xFF133E38);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF122220),
                    const Color(0xFF0C1413),
                  ]
                : [
                    const Color(0xFFF2F9F7),
                    const Color(0xFFE4F3EE),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 40),

              // Logo et Titre avec animations
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icône Splitzo avec fond élégant
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: primaryTeal.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryTeal.withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 52,
                            color: primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nom de l'application
                      Text(
                        'Splitzo',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: isDark ? const Color(0xFFE2F3EE) : deepTeal,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle in English
                      Text(
                        'Easy bill splitting & tip calculation',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4A6B65),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? primaryTeal : deepTeal,
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
