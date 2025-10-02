import 'package:flutter/material.dart';
import 'package:snapalyze/shared/app_theme.dart';
import 'package:snapalyze/authentication/auth_screen.dart';
import 'package:snapalyze/onboarding/fade_animation.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int totalPage = 4;
  int currentPage = 0;
  bool _isLastPage = false;

  void _onScroll() {
    setState(() {
      currentPage = _pageController.page?.round() ?? 0;
      _isLastPage = currentPage == totalPage - 1;
    });
  }

  @override
  void initState() {
    _pageController = PageController(initialPage: 0)..addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToAuth() {
    Navigator.pushReplacementNamed(context, AuthScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                currentPage = page;
                _isLastPage = page == totalPage - 1;
              });
            },
            children: <Widget>[
              makePage(
                page: 1,
                image: 'assets/onboarding/visionary.png',
                description:
                    'Discover a smarter way to understand the world through your photos.',
              ),
              makePage(
                page: 2,
                image: 'assets/onboarding/imageanalysis.png',
                description:
                    "Our smart engine scans your images and explains exactly what’s inside.",
              ),
              makePage(
                page: 3,
                image: 'assets/onboarding/imagedisplay.png',
                description:
                    "Choose from your gallery or take a new picture — let AI do the analysis instantly.",
              ),
              makePage(
                page: 4,

                image: 'assets/onboarding/share.png',
                description:
                    "Spread the Magic\nLove it? Share this amazing app with your friends and let them see the power of AI too.",
                isLastPage: true,
              ),
            ],
          ),

          // // Skip button (not on last page)
          // if (!_isLastPage)
          //   Positioned(
          //     top: MediaQuery.of(context).padding.top + 20,
          //     right: 20,
          //     child: FadeAnimation(
          //       0.5,
          //       TextButton(
          //         onPressed: _goToAuth,
          //         child: const Text(
          //           'Skip',
          //           style: TextStyle(
          //             color: Colors.white,
          //             fontSize: 16,
          //             fontWeight: FontWeight.w500,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),

          // Page indicator
          Positioned(
            bottom: _isLastPage ? 100 : 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPage, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentPage == index
                        ? AppTheme.white
                        : AppTheme.white.withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ),

          // Get Started Button on last page
          if (_isLastPage)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: FadeAnimation(
                1.0,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.white,
                      foregroundColor: AppTheme.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _goToAuth,
                    child: const Text(
                      'GET STARTED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget makePage({image, description, page, bool isLastPage = false}) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.fill),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            stops: const [0.3, 0.9],
            colors: [
              AppTheme.black.withValues(alpha: 0.9),
              AppTheme.black.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).padding.top + 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  FadeAnimation(
                    0.5,
                    Text(
                      page.toString(),
                      style: const TextStyle(
                        color: AppTheme.black,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text(
                    '/4',
                    style: TextStyle(color: AppTheme.black, fontSize: 15),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: .1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: FadeAnimation(
                        2,
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.black,
                            height: 1.6,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
