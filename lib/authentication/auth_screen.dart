import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snapalyze/authentication/login_form.dart';
import 'package:snapalyze/authentication/register_form.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = '/AuthScreen';
  const AuthScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;
  late Animation<double> _animation4;
  bool isLogin = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation1 =
        Tween<double>(begin: .1, end: .15).animate(
            CurvedAnimation(parent: _controller1, curve: Curves.easeInOut),
          )
          ..addListener(() => setState(() {}))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _controller1.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _controller1.forward();
            }
          });

    _animation2 = Tween<double>(begin: .02, end: .04).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation3 =
        Tween<double>(begin: .41, end: .38).animate(
            CurvedAnimation(parent: _controller2, curve: Curves.easeInOut),
          )
          ..addListener(() => setState(() {}))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _controller2.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _controller2.forward();
            }
          });

    _animation4 = Tween<double>(begin: 170, end: 190).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    Timer(const Duration(seconds: 2), () => _controller1.forward());
    _controller2.forward();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  void smoothMove(bool flag) {
    setState(() {
      isLogin = flag;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff192028),
      body: ScrollConfiguration(
        behavior: MyBehavior(),
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height,
            child: Stack(
              children: [
                // Background animated circles - BEHIND everything
                _buildAnimatedCircles(size),

                // Main content - ABOVE the circles
                isLogin
                    ? Positioned.fill(child: LoginForm(move: smoothMove))
                    : Positioned.fill(child: RegisterForm(move: smoothMove)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCircles(Size size) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: size.height * (_animation2.value + .62),
            left: size.width * .21,
            child: CustomPaint(painter: MyPainter(25)),
          ),
          Positioned(
            top: size.height * .98,
            left: size.width * .1,
            child: CustomPaint(painter: MyPainter(_animation4.value - 30)),
          ),
          Positioned(
            top: size.height * .5,
            left: size.width * (_animation2.value + .8),
            child: CustomPaint(painter: MyPainter(30)),
          ),
          Positioned(
            top: size.height * _animation3.value,
            left: size.width * (_animation1.value + .1),
            child: CustomPaint(painter: MyPainter(60)),
          ),
          Positioned(
            top: size.height * .1,
            left: size.width * .8,
            child: CustomPaint(painter: MyPainter(_animation4.value)),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Animated Circles
class MyPainter extends CustomPainter {
  final double radius;

  MyPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xffFD5E3D).withValues(alpha: 0.1),

          Colors.blue.withValues(alpha: 0.2),
          const Color.fromARGB(255, 17, 17, 17).withValues(alpha: 0.6),

          const Color(0xffFD5E3D).withValues(alpha: 0.4),
        ],

        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawCircle(Offset.zero, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Scroll Behavior
class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
