// lib/authentication/auth_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snapalyze/authentication/login_form.dart';
import 'package:snapalyze/authentication/register_form.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = '/AuthScreen';
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;
  late Animation<double> _animation4;

  Timer? _delayStart; // <-- track the delayed start
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

    _animation1 = Tween<double>(begin: .1, end: .15).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    _animation2 = Tween<double>(begin: .02, end: .04).animate(
      CurvedAnimation(parent: _controller1, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation3 = Tween<double>(begin: .41, end: .38).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    _animation4 = Tween<double>(begin: 170, end: 190).animate(
      CurvedAnimation(parent: _controller2, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    // Start controller2 immediately in a ping-pong loop
    _controller2.repeat(reverse: true);

    // Start controller1 after 2 seconds, safely
    _delayStart = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      // Loop it too; this replaces the old status listeners
      _controller1.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _delayStart?.cancel(); // <-- important
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
      body: Stack(
        children: [
          _buildAnimatedCircles(size),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: isLogin
                    ? LoginForm(move: smoothMove)
                    : RegisterForm(move: smoothMove),
              ),
            ),
          ),
        ],
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
          Positioned(
            top: size.height * .7,
            left: size.width * (_animation1.value + .6),
            child: CustomPaint(painter: MyPainter(8)),
          ),
          Positioned(
            top: size.height * .85,
            left: size.width * (_animation1.value + .7),
            child: CustomPaint(painter: MyPainter(25)),
          ),
        ],
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final double radius;
  MyPainter(this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xffFD5E3D).withAlpha(255 ~/ 10),
          Colors.blue.withAlpha(255 ~/ 5),
          const Color.fromARGB(255, 17, 17, 17).withAlpha(255 ~/ 1.7),
          const Color(0xffFD5E3D).withAlpha(255 ~/ 2.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawCircle(Offset.zero, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
