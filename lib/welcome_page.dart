// lib\welcome_page.dart


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'home_page.dart';
import 'features/cricket_scoring/screens/auth/google_signin_screen.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onThemeChanged;
  final ThemeMode currentTheme;

  const WelcomePage({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnimations = List.generate(
      4,
          (index) => Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.1 * index,
          0.5 + 0.1 * index,
          curve: Curves.easeOutCubic,
        ),
      )),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    const primaryAccentColor = Color(0xFF4CAF50);
    const secondaryColor = Color(0xFFFF6F00);
    const textColor = Colors.white;
    const subtitleColor = Color(0xFFCFD8DC);

    const cardBackgroundColor = Color(0x66000000);

    const cardBorderColor = Color(0x33FFFFFF);


    return Scaffold(
      body: Container(

        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/stadium_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(

          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [


                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isSmallScreen = screenWidth < 400;

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16.0 : 24.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: isSmallScreen ? 20 : 40),

                          _AnimatedSlideFade(
                            slideAnimation: _slideAnimations[0],
                            fadeAnimation: _fadeAnimation,
                            child: _EnhancedCricketLogo(
                              size: isSmallScreen ? 100 : 120,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),

                          _AnimatedSlideFade(
                            slideAnimation: _slideAnimations[1],
                            fadeAnimation: _fadeAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Scorepad Pro',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 28 : 36,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cricket Scoring System',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 18 : 24,
                                    fontWeight: FontWeight.w600,
                                    color: primaryAccentColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),

                          _AnimatedSlideFade(
                            slideAnimation: _slideAnimations[2],
                            fadeAnimation: _fadeAnimation,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 10 : 12,
                              ),
                              decoration: BoxDecoration(
                                color: cardBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cardBorderColor),
                              ),
                              child: Text(
                                'Professional Cricket Match Management\n& Live Scoring Platform',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: subtitleColor,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 40),

                          _AnimatedSlideFade(
                            slideAnimation: _slideAnimations[2],
                            fadeAnimation: _fadeAnimation,
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                              decoration: BoxDecoration(
                                color: cardBackgroundColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  if (isSmallScreen)

                                    Column(
                                      children: [
                                        _FeatureItem(
                                          icon: Icons.sports_cricket,
                                          label: 'Live Scoring',
                                          color: primaryAccentColor,
                                          isSmallScreen: true,
                                          textColor: textColor,
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _FeatureItem(
                                              icon: Icons.analytics,
                                              label: 'Statistics',
                                              color: secondaryColor,
                                              isSmallScreen: true,
                                              textColor: textColor,
                                            ),
                                            _FeatureItem(
                                              icon: Icons.people,
                                              label: 'Team Management',
                                              color: Colors.blueAccent,
                                              isSmallScreen: true,
                                              textColor: textColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else

                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _FeatureItem(
                                          icon: Icons.sports_cricket,
                                          label: 'Live Scoring',
                                          color: primaryAccentColor,
                                          isSmallScreen: false,
                                          textColor: textColor,
                                        ),
                                        _FeatureItem(
                                          icon: Icons.analytics,
                                          label: 'Statistics',
                                          color: secondaryColor,
                                          isSmallScreen: false,
                                          textColor: textColor,
                                        ),
                                        _FeatureItem(
                                          icon: Icons.people,
                                          label: 'Team Management',
                                          color: Colors.blueAccent,
                                          isSmallScreen: false,
                                          textColor: textColor,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 32),

                          _AnimatedSlideFade(
                            slideAnimation: _slideAnimations[3],
                            fadeAnimation: _fadeAnimation,
                            child: Column(
                              children: [

                                _GoogleSignInButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const GoogleSignInScreen(),
                                      ),
                                    );
                                  },
                                  isSmallScreen: isSmallScreen,
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),

                                Row(
                                  children: [
                                    Expanded(
                                        child: Divider(
                                            color: subtitleColor.withOpacity(0.3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: GoogleFonts.inter(
                                          color: subtitleColor.withOpacity(0.6),
                                          fontSize: isSmallScreen ? 10 : 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                        child: Divider(
                                            color: subtitleColor.withOpacity(0.3))),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),

                                _EnhancedCricketButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) => HomePage(
                                          onThemeChanged: widget.onThemeChanged,
                                          currentTheme: widget.currentTheme,
                                        ),
                                        transitionDuration:
                                        const Duration(milliseconds: 500),
                                        transitionsBuilder:
                                            (_, animation, __, child) {
                                          return FadeTransition(
                                              opacity: animation, child: child);
                                        },
                                      ),
                                    );
                                  },
                                  isSmallScreen: isSmallScreen,
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                Text(
                                  "Developed By ITJ Team",
                                  style: GoogleFonts.inter(
                                    color: subtitleColor.withOpacity(0.7),
                                    fontSize: isSmallScreen ? 10 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSlideFade extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final Widget child;

  const _AnimatedSlideFade({
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}



class _EnhancedCricketLogo extends StatelessWidget {
  final double size;

  const _EnhancedCricketLogo({this.size = 120});

  @override
  Widget build(BuildContext context) {
    final scale = size / 120;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
          ],
        ),
        borderRadius: BorderRadius.circular(30 * scale),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 30 * scale,
            spreadRadius: 0,
            offset: Offset(0, 15 * scale),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [

          Positioned(
            left: 20 * scale,
            child: Container(
              width: 8 * scale,
              height: 60 * scale,
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63),
                borderRadius: BorderRadius.circular(4 * scale),
              ),
            ),
          ),

          Positioned(
            right: 25 * scale,
            top: 30 * scale,
            child: Container(
              width: 20 * scale,
              height: 20 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: 20 * scale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                    (index) => Container(
                  width: 3 * scale,
                  height: 25 * scale,
                  margin: EdgeInsets.symmetric(horizontal: 1 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(1.5 * scale),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSmallScreen;
  final Color textColor;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSmallScreen,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isSmallScreen ? 40.0 : 50.0;
    final iconInnerSize = isSmallScreen ? 20.0 : 24.0;
    final fontSize = isSmallScreen ? 10.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: color,
            size: iconInnerSize,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _GoogleSignInButton({
    required this.onPressed,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmallScreen ? 50.0 : 60.0;
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final horizontalPadding = isSmallScreen ? 24.0 : 32.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          'https://developers.google.com/identity/images/g-logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'Continue with Google',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D2A38),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnhancedCricketButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const _EnhancedCricketButton({
    required this.onPressed,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = isSmallScreen ? 50.0 : 60.0;
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final horizontalPadding = isSmallScreen ? 24.0 : 32.0;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_cricket,
                  color: Colors.white,
                  size: iconSize,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'Start Cricket Journey',
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 16 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}