// auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:foodshare/auth/auth_gate.dart';
import 'package:foodshare/auth/auth_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to FoodShare",
      subtitle: "Fighting hunger together 🤝",
      description:
          "Join our community dedicated to reducing food waste and helping those in need through the power of sharing.",
      icon: Icons.restaurant_menu,
      image: "lib/assets/2.png",
      color: const Color.fromARGB(255, 19, 30, 20),
    ),
    OnboardingPage(
      title: "For Restaurants",
      subtitle: "Share your surplus food",
      description:
          "Transform your excess food into hope. Connect with local shelters and make a meaningful impact in your community.",
      icon: Icons.restaurant,
      color: const Color(0xFF1565C0),
      features: [
        "📦 Share surplus food easily",
        "🤝 Connect with local shelters",
        "📊 Track your impact",
        "🌍 Build community relationships",
      ],
    ),
    OnboardingPage(
      title: "For Shelters & NGOs",
      subtitle: "Access fresh food donations",
      description:
          "Get connected with restaurants and food businesses to receive fresh donations for the people you serve.",
      icon: Icons.home,
      color: const Color(0xFF7B1FA2),
      features: [
        "🍽️ Access fresh food donations",
        "🏪 Connect with local restaurants",
        "👥 Serve more people in need",
        "💚 Build sustainable partnerships",
      ],
    ),
    OnboardingPage(
      title: "Make a Difference",
      subtitle: "Every meal matters",
      description:
          "Together, we can reduce food waste and ensure no one goes hungry. Your participation makes a real difference.",
      icon: Icons.favorite,
      color: const Color(0xFFD32F2F),
      features: [
        "🌱 Reduce food waste",
        "❤️ Help feed the hungry",
        "📱 Simple and easy to use",
        "🔒 Safe and secure platform",
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // Start initial animations
    _startPageAnimations();
  }

  void _startPageAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    // Staggered bounce animation for features
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _bounceController.forward();
    });
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    _bounceController.reset();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _resetAnimations();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _resetAnimations();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  void _goToRegister() async {
    // Mark onboarding as complete
    await _markOnboardingComplete();

    // Navigate to AuthPage instead of directly to RegisterScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _goToLogin() async {
    // Mark onboarding as complete
    await _markOnboardingComplete();

    // Navigate to AuthPage instead of directly to LoginScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              _pages[_currentPage].color.withAlpha(25),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button with fade animation
              AnimatedOpacity(
                opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(75)),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(180),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // PageView with animations
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                    _resetAnimations();
                    _startPageAnimations();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Bottom section with indicators and buttons
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Animated page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? _pages[_currentPage].color
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(75),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: _pages[_currentPage].color
                                          .withAlpha(100),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Animated buttons
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _currentPage < _pages.length - 1
                          ? _buildNavigationButtons()
                          : _buildFinalButtons(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      key: const ValueKey('navigation'),
      children: [
        // Animated Next button
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.9 + (0.1 * value),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      _pages[_currentPage].color,
                      _pages[_currentPage].color.withAlpha(200),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _pages[_currentPage].color.withAlpha(75),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(4 * value, 0),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        if (_currentPage > 0)
          TextButton(
            onPressed: _previousPage,
            child: Text(
              'Previous',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(175),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFinalButtons() {
    return Column(
      key: const ValueKey('final'),
      children: [
        // Animated Get Started button
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withAlpha(100),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _goToRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        // Animated sign in link
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(175),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color.fromARGB(231, 24, 60, 45),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon or Image
          SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        page.color.withAlpha(5),
                        page.color.withAlpha(13),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withAlpha(50),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: page.image != null
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(page.image!, fit: BoxFit.contain),
                        )
                      : Icon(page.icon, size: 70, color: page.color),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Animated Title
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                  ),
                ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                page.title,
                style: GoogleFonts.bebasNeue(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Animated Subtitle
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: page.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: page.color.withAlpha(75)),
                ),
                child: Text(
                  page.subtitle,
                  style: TextStyle(
                    color: page.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Animated Description
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                  ),
                ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                page.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Animated Features list
          if (page.features != null) ...[
            const SizedBox(height: 30),
            ScaleTransition(
              scale: _bounceAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        page.color.withAlpha(13),
                        page.color.withAlpha(5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: page.color.withAlpha(5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withAlpha(25),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: page.features!.asMap().entries.map((entry) {
                      return TweenAnimationBuilder<double>(
                        duration: Duration(
                          milliseconds: 300 + (entry.key * 100),
                        ),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: page.color,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(200),
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String? image;
  final List<String>? features;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.image,
    this.features,
  });
}
