import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:meditation/shared/app_components.dart';
import 'package:meditation/shared/app_layout.dart';
import 'package:meditation/auth/auth_page.dart';
import 'package:meditation/app/seren_experience.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double _breathingWaveTileWidthFactor = 4;

double _breathPhaseProgress(double cycleProgress) {
  return cycleProgress < 0.5 ? cycleProgress * 2 : (cycleProgress - 0.5) * 2;
}

double _breathVerticalOffset({
  required double cycleProgress,
  required double travel,
}) {
  final phaseProgress = _breathPhaseProgress(cycleProgress);
  final easedProgress = Curves.easeInOutSine.transform(phaseProgress);
  final isInhale = cycleProgress < 0.5;
  final start = isInhale ? travel : -travel;
  final end = isInhale ? -travel : travel;

  return start + ((end - start) * easedProgress);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  String? setupError;
  if (url.isEmpty || key.isEmpty) {
    setupError = 'Supabase is not configured. Add the project URL and publishable key to run this app.';
  } else {
    try {
      await Supabase.initialize(url: url, publishableKey: key);
    } catch (error) {
      setupError = 'Supabase could not start: $error';
    }
  }
  runApp(MainApp(setupError: setupError));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.setupError});

  final String? setupError;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _introFinished = false;
  bool _signedIn = false;
  bool _recoveringPassword = false;
  int _authGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.setupError == null) {
      _signedIn = Supabase.instance.client.auth.currentSession != null;
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((state) {
            final signedIn = state.session != null;
            final recovering = state.event == AuthChangeEvent.passwordRecovery;
            if (!mounted || (signedIn == _signedIn && !recovering)) return;
            setState(() {
              _signedIn = signedIn;
              _recoveringPassword = recovering;
              _authGeneration++;
            });
          });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_authGeneration),
      debugShowCheckedModeBanner: false,
      home: !_introFinished
          ? SerenHomePage(
              onFinished: () => setState(() => _introFinished = true),
            )
          : widget.setupError != null
          ? SetupErrorPage(message: widget.setupError!)
          : _recoveringPassword
          ? ResetPasswordPage(
              onComplete: () => setState(() {
                _recoveringPassword = false;
                _authGeneration++;
              }),
            )
          : _signedIn
          ? const SerenExperience()
          : Builder(
              builder: (authContext) => AuthPage(
                onExplore: () =>
                    Navigator.of(authContext)
                        .push(_fadeRoute(const WelcomePage())),
              ),
            ),
    );
  }
}

class SerenHomePage extends StatefulWidget {
  const SerenHomePage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SerenHomePage> createState() => _SerenHomePageState();
}

class _SerenHomePageState extends State<SerenHomePage> {
  static const String _videoPath = 'assets/intro_video/seren_intro.mp4';
  static const String _posterPath = 'assets/intro_video/seren_intro_poster.jpg';

  late final VideoPlayerController _videoController;
  Timer? _navigationTimer;
  bool _videoReady = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(_videoPath)
      ..addListener(_handleVideoProgress);
    unawaited(_startIntro());
  }

  Future<void> _startIntro() async {
    try {
      await _videoController.initialize();
      await _videoController.setLooping(false);
      await _videoController.setVolume(0);
      if (!mounted) return;
      setState(() => _videoReady = true);
      await _videoController.play();
      _navigationTimer = Timer(
        _videoController.value.duration + const Duration(seconds: 1),
        _finishIntro,
      );
    } catch (error) {
      debugPrint('Intro video failed: $error');
      _navigationTimer = Timer(const Duration(seconds: 5), _finishIntro);
    }
  }

  void _handleVideoProgress() {
    if (!_videoController.value.isInitialized) return;
    final remaining =
        _videoController.value.duration - _videoController.value.position;
    if (remaining <= const Duration(milliseconds: 80)) _finishIntro();
  }

  void _finishIntro() {
    if (!mounted || _finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _videoController
      ..removeListener(_handleVideoProgress)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07110E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_posterPath, fit: BoxFit.cover),
          if (_videoReady)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
        ],
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const String _branchPath = 'assets/icons/branch.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final horizontalPadding = AppLayout.horizontalPadding(context);
    final branchSize = (shortestSide * 0.21).clamp(72.0, 112.0).toDouble();
    final titleSize = (shortestSide * 0.115).clamp(38.0, 52.0).toDouble();
    final bodySize = (shortestSide * 0.052).clamp(18.0, 23.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF7),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              const Spacer(flex: 4),
              Image.asset(
                _branchPath,
                width: branchSize,
                height: branchSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 38),
              Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF263746),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "Take a deep breath.\nYou're in the right place.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3E4B56),
                  fontSize: bodySize,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const Spacer(flex: 5),
              AppPrimaryButton(
                label: "Let's Begin",
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const BreathingAnimationPage(),
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Let's Begin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 22),
                    Icon(Icons.arrow_forward, size: 28),
                  ],
                ),
              ),
              SizedBox(
                height: (size.height * 0.09).clamp(52.0, 86.0).toDouble(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreathingAnimationPage extends StatefulWidget {
  const BreathingAnimationPage({super.key});

  @override
  State<BreathingAnimationPage> createState() => _BreathingAnimationPageState();
}

class _BreathingAnimationPageState extends State<BreathingAnimationPage>
    with TickerProviderStateMixin {
  static const String _backgroundPath = 'assets/breathing/background.png';
  static const String _wavePath = 'assets/breathing/wave.png';
  static const String _ballPath = 'assets/breathing/glowing_ball.png';
  static const Duration _breathDuration = Duration(seconds: 4);
  static const Duration _waveTravelDuration = Duration(seconds: 56);

  late final AnimationController _breathController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _breathController =
        AnimationController(vsync: this, duration: _breathDuration * 2)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _showCompletionPage();
            }
          })
          ..forward();
    _waveController = AnimationController(
      vsync: this,
      duration: _waveTravelDuration,
    )..repeat();
  }

  void _showCompletionPage() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BreathingCompletionPage(),
        transitionDuration: const Duration(milliseconds: 650),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final titleSize = (shortestSide * 0.075).clamp(26.0, 36.0).toDouble();
    final subtitleSize = (shortestSide * 0.042).clamp(15.0, 19.0).toDouble();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00436582),
                  Color(0x227CA5C6),
                  Color(0x66F7F4EF),
                ],
                stops: [0.0, 0.48, 1.0],
              ),
            ),
          ),
          _ScrollingWave(
            breathAnimation: _breathController,
            scrollAnimation: _waveController,
            wavePath: _wavePath,
          ),
          Align(
            alignment: Alignment.center,
            child: _CenteredBreathingBall(
              animation: _breathController,
              ballPath: _ballPath,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: (size.height * 0.12).clamp(70.0, 120.0).toDouble(),
                ),
                Text(
                  'Breathe With Us',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Follow the light. Breathe in, breathe out.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xE6F4F7FA),
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                    shadows: const [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _BreathingCue(animation: _breathController),
                SizedBox(
                  height: (size.height * 0.16).clamp(100.0, 150.0).toDouble(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollingWave extends StatelessWidget {
  const _ScrollingWave({
    required this.breathAnimation,
    required this.scrollAnimation,
    required this.wavePath,
  });

  final Animation<double> breathAnimation;
  final Animation<double> scrollAnimation;
  final String wavePath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final waveHeight = (screenWidth * 0.48).clamp(150.0, 250.0).toDouble();
    final tileWidth = screenWidth * _breathingWaveTileWidthFactor;
    final verticalTravel = (screenWidth * 0.18).clamp(58.0, 82.0).toDouble();

    return Positioned(
      top: (size.height - waveHeight) / 2,
      left: 0,
      right: 0,
      height: waveHeight,
      child: AnimatedBuilder(
        animation: Listenable.merge([breathAnimation, scrollAnimation]),
        builder: (context, _) {
          final waveOffsetX = -scrollAnimation.value * tileWidth;
          final waveOffsetY = _breathVerticalOffset(
            cycleProgress: breathAnimation.value,
            travel: verticalTravel,
          );

          return ClipRect(
            child: Transform.translate(
              offset: Offset(0, waveOffsetY),
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(2, (index) {
                  return Positioned(
                    left: waveOffsetX + (index * tileWidth),
                    top: 0,
                    width: tileWidth,
                    height: waveHeight,
                    child: Image.asset(
                      wavePath,
                      fit: BoxFit.fill,
                      alignment: Alignment.center,
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CenteredBreathingBall extends StatelessWidget {
  const _CenteredBreathingBall({
    required this.animation,
    required this.ballPath,
  });

  final Animation<double> animation;
  final String ballPath;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ballSize = (screenWidth * 0.17).clamp(62.0, 88.0).toDouble();
    final verticalTravel = (screenWidth * 0.18).clamp(58.0, 82.0).toDouble();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final yOffset = _breathVerticalOffset(
            cycleProgress: animation.value,
            travel: verticalTravel,
          );

          return Transform.translate(
            offset: Offset(0, yOffset),
            child: Image.asset(
              ballPath,
              width: ballSize,
              height: ballSize,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}

class _BreathingCue extends StatelessWidget {
  const _BreathingCue({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final cycleProgress = animation.value;
        final isInhale = cycleProgress < 0.5;
        final phaseProgress = isInhale
            ? cycleProgress * 2
            : (cycleProgress - 0.5) * 2;
        final seconds = (4 - (phaseProgress * 4).floor()).clamp(1, 4);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isInhale ? 'Inhale' : 'Exhale',
              style: const TextStyle(
                color: Color(0xFF2D3F4D),
                fontSize: 30,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$seconds',
              style: const TextStyle(
                color: Color(0xFF2D3F4D),
                fontSize: 42,
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}

class BreathingCompletionPage extends StatelessWidget {
  const BreathingCompletionPage({super.key});

  static const String _backgroundPath = 'assets/breathing/background.png';
  static const String _ballPath = 'assets/breathing/glowing_ball.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final horizontalPadding = AppLayout.horizontalPadding(context);
    final titleSize = (shortestSide * 0.09).clamp(34.0, 46.0).toDouble();
    final bodySize = (shortestSide * 0.047).clamp(17.0, 21.0).toDouble();
    final orbSize = (shortestSide * 0.48).clamp(170.0, 230.0).toDouble();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x117CA5C6),
                  Color(0x22F7F4EF),
                  Color(0x668CADBF),
                ],
                stops: [0.0, 0.58, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  SizedBox(
                    height: (size.height * 0.18).clamp(112.0, 170.0).toDouble(),
                  ),
                  Text(
                    'Well done',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF263746),
                      fontSize: titleSize,
                      fontWeight: FontWeight.w400,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "You've taken the first step\ntowards a calmer mind.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF3E4B56),
                      fontSize: bodySize,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(
                    height: (size.height * 0.08).clamp(48.0, 76.0).toDouble(),
                  ),
                  _CompletionOrb(ballPath: _ballPath, size: orbSize),
                  const Spacer(),
                  AppPrimaryButton(
                    label: 'Continue',
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          pageBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                          ) => const MeditationGoalQuestionPage(),
                          transitionDuration: const Duration(milliseconds: 500),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: (size.height * 0.09).clamp(52.0, 86.0).toDouble(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionOrb extends StatefulWidget {
  const _CompletionOrb({required this.ballPath, required this.size});

  final String ballPath;
  final double size;

  @override
  State<_CompletionOrb> createState() => _CompletionOrbState();
}

class _CompletionOrbState extends State<_CompletionOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.7,
      height: widget.size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: widget.size * 0.05,
            child: AnimatedBuilder(
              animation: _rippleController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size * 1.55, widget.size * 0.58),
                  painter: _CompletionRingsPainter(
                    progress: _rippleController.value,
                  ),
                );
              },
            ),
          ),
          Image.asset(
            widget.ballPath,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _CompletionRingsPainter extends CustomPainter {
  const _CompletionRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    final center = Offset(size.width / 2, size.height * 0.48);

    for (var index = 0; index < 5; index++) {
      final rippleProgress = (progress + (index * 0.2)) % 1;
      final easedProgress = Curves.easeOutCubic.transform(rippleProgress);
      final width = size.width * (0.3 + (easedProgress * 0.7));
      final height = size.height * (0.16 + (easedProgress * 0.44));
      final alpha = (1 - easedProgress) * 0.46;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: width, height: height),
        paint..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class MeditationGoalQuestionPage extends StatefulWidget {
  const MeditationGoalQuestionPage({super.key});

  @override
  State<MeditationGoalQuestionPage> createState() =>
      _MeditationGoalQuestionPageState();
}

class _MeditationGoalQuestionPageState
    extends State<MeditationGoalQuestionPage> {
  static const List<String> _options = [
    'Reduce stress or anxiety',
    'Sleep better',
    'Be more present',
    'Improve focus',
    'Other',
  ];

  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return OnboardingOptionQuestionPage(
      step: 1,
      title: 'Why do you want\nto start meditating?',
      options: _options,
      selectedOption: _selectedOption,
      onOptionSelected: (option) {
        setState(() {
          _selectedOption = option;
        });
      },
      onNext: _selectedOption == null
          ? null
          : () {
              Navigator.of(context).push(_fadeRoute(const MoodQuestionPage()));
            },
    );
  }
}

class _QuestionProgressHeader extends StatelessWidget {
  const _QuestionProgressHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.chevron_left_rounded),
          color: const Color(0xFF263746),
          iconSize: 32,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        ),
        const SizedBox(width: 28),
        Expanded(child: _QuestionProgressBar(progress: step / 4)),
        const SizedBox(width: 34),
        Text(
          '$step/4',
          style: TextStyle(
            color: Color(0xFF263746),
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuestionProgressBar extends StatelessWidget {
  const _QuestionProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFE1E4E5)),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF2F3E49)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Route<void> _fadeRoute(Widget page) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 500),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class OnboardingOptionQuestionPage extends StatelessWidget {
  const OnboardingOptionQuestionPage({
    super.key,
    required this.step,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onNext,
  });

  final int step;
  final String title;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final titleSize = (shortestSide * 0.068).clamp(27.0, 36.0).toDouble();
    final optionFontSize = (shortestSide * 0.04).clamp(15.5, 18.0).toDouble();
    final optionHeight = (size.height * 0.067).clamp(54.0, 62.0).toDouble();

    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 22),
          _QuestionProgressHeader(step: step),
          SizedBox(height: (size.height * 0.052).clamp(32.0, 48.0).toDouble()),
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF263746),
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.28,
            ),
          ),
          SizedBox(height: (size.height * 0.032).clamp(22.0, 32.0).toDouble()),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppOptionPill(
                label: option,
                isSelected: option == selectedOption,
                fontSize: optionFontSize,
                height: optionHeight,
                onTap: () {
                  onOptionSelected(option);
                },
              ),
            ),
          ),
          SizedBox(height: (size.height * 0.055).clamp(28.0, 56.0).toDouble()),
          AppPrimaryButton(label: 'Next', onPressed: onNext),
          SizedBox(height: (size.height * 0.045).clamp(28.0, 44.0).toDouble()),
        ],
      ),
    );
  }
}

class MoodQuestionPage extends StatefulWidget {
  const MoodQuestionPage({super.key});

  @override
  State<MoodQuestionPage> createState() => _MoodQuestionPageState();
}

class _MoodQuestionPageState extends State<MoodQuestionPage> {
  static const List<_MoodOption> _moods = [
    _MoodOption(label: 'Stressed', icon: Icons.sentiment_very_dissatisfied),
    _MoodOption(label: 'Anxious', icon: Icons.sentiment_dissatisfied),
    _MoodOption(label: 'Tired', icon: Icons.sentiment_dissatisfied_outlined),
    _MoodOption(label: 'Neutral', icon: Icons.sentiment_neutral),
    _MoodOption(label: 'Good', icon: Icons.sentiment_satisfied),
    _MoodOption(label: 'Great', icon: Icons.sentiment_very_satisfied),
  ];

  String? _selectedMood;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final titleSize = (shortestSide * 0.073).clamp(28.0, 38.0).toDouble();
    final labelSize = (shortestSide * 0.039).clamp(15.0, 18.0).toDouble();
    final circleSize = (shortestSide * 0.2).clamp(72.0, 92.0).toDouble();
    final moodSpacing = (shortestSide * 0.09).clamp(28.0, 44.0).toDouble();
    final moodContentWidth =
        (size.width.clamp(0.0, AppLayout.maxContentWidth) -
                (AppLayout.horizontalPadding(context) * 2))
            .toDouble();
    final moodTileWidth = ((moodContentWidth - 24) / 3)
        .clamp(86.0, 116.0)
        .toDouble();

    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          const _QuestionProgressHeader(step: 2),
          SizedBox(height: (size.height * 0.07).clamp(44.0, 68.0).toDouble()),
          Text(
            'How are you feeling\ntoday?',
            style: TextStyle(
              color: const Color(0xFF263746),
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.28,
            ),
          ),
          SizedBox(height: (size.height * 0.07).clamp(44.0, 64.0).toDouble()),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: moodSpacing,
            spacing: 12,
            children: _moods.map((mood) {
              return SizedBox(
                width: moodTileWidth,
                child: _MoodButton(
                  mood: mood,
                  isSelected: mood.label == _selectedMood,
                  circleSize: circleSize,
                  labelSize: labelSize,
                  onTap: () {
                    setState(() {
                      _selectedMood = mood.label;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          SizedBox(height: (size.height * 0.08).clamp(44.0, 88.0).toDouble()),
          AppPrimaryButton(
            label: 'Next',
            onPressed: _selectedMood == null
                ? null
                : () {
                    Navigator.of(context)
                        .push(_fadeRoute(const AppGainQuestionPage()));
                  },
          ),
          SizedBox(height: (size.height * 0.06).clamp(36.0, 58.0).toDouble()),
        ],
      ),
    );
  }
}

class _MoodOption {
  const _MoodOption({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.circleSize,
    required this.labelSize,
    required this.onTap,
  });

  final _MoodOption mood;
  final bool isSelected;
  final double circleSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFFD9E3E8)
                  : const Color(0xFFE8E2DA),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6F8796)
                    : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Icon(mood.icon, color: const Color(0xFF53616B), size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            mood.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF53616B),
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class AppGainQuestionPage extends StatefulWidget {
  const AppGainQuestionPage({super.key});

  @override
  State<AppGainQuestionPage> createState() => _AppGainQuestionPageState();
}

class _AppGainQuestionPageState extends State<AppGainQuestionPage> {
  static const List<String> _options = [
    'A calmer mind',
    'Better sleep',
    'More focus and productivity',
    'A more positive mindset',
    'Other',
  ];

  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return OnboardingOptionQuestionPage(
      step: 3,
      title: 'What are you hoping\nto gain from this app?',
      options: _options,
      selectedOption: _selectedOption,
      onOptionSelected: (option) {
        setState(() {
          _selectedOption = option;
        });
      },
      onNext: _selectedOption == null
          ? null
          : () {
              Navigator.of(context)
                  .push(_fadeRoute(const MeditationFrequencyQuestionPage()));
            },
    );
  }
}

class MeditationFrequencyQuestionPage extends StatefulWidget {
  const MeditationFrequencyQuestionPage({super.key});

  @override
  State<MeditationFrequencyQuestionPage> createState() =>
      _MeditationFrequencyQuestionPageState();
}

class _MeditationFrequencyQuestionPageState
    extends State<MeditationFrequencyQuestionPage> {
  static const List<String> _options = [
    'Daily',
    'A few times a week',
    'Once a week',
    "I'm not sure yet",
  ];

  String? _selectedOption;

  @override
  Widget build(BuildContext context) {
    return OnboardingOptionQuestionPage(
      step: 4,
      title: 'How often do you plan\nto meditate?',
      options: _options,
      selectedOption: _selectedOption,
      onOptionSelected: (option) {
        setState(() {
          _selectedOption = option;
        });
      },
      onNext: _selectedOption == null
          ? null
          : () {
              Navigator.of(context).push(_fadeRoute(const ReadyPage()));
            },
    );
  }
}

class ReadyPage extends StatelessWidget {
  const ReadyPage({super.key});

  static const String _backgroundPath =
      'assets/backgrounds/ChatGPT Image Sep 15, 2026, 06_05_06 PM.png';
  static const String _branchPath = 'assets/icons/branch.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final horizontalPadding = AppLayout.horizontalPadding(context);
    final branchSize = (shortestSide * 0.18).clamp(62.0, 88.0).toDouble();
    final titleSize = (shortestSide * 0.078).clamp(30.0, 42.0).toDouble();
    final bodySize = (shortestSide * 0.042).clamp(16.0, 20.0).toDouble();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x33385975),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      SizedBox(
                        height: (size.height * 0.13)
                            .clamp(82.0, 128.0)
                            .toDouble(),
                      ),
                      Image.asset(
                        _branchPath,
                        width: branchSize,
                        height: branchSize,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "You're Ready",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF263746),
                          fontSize: titleSize,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "You've set your intention.\nNow it's time to begin your journey\nto a calmer, brighter you.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF3E4B56),
                          fontSize: bodySize,
                          fontWeight: FontWeight.w500,
                          height: 1.32,
                        ),
                      ),
                      const Spacer(),
                      AppPrimaryButton(
                        label: 'Continue to Plans',
                        onPressed: () {
                          Navigator.of(context)
                              .push(_fadeRoute(const PremiumOfferPage()));
                        },
                      ),
                      SizedBox(
                        height: (size.height * 0.075)
                            .clamp(44.0, 70.0)
                            .toDouble(),
                      ),
                    ],
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

class PremiumOfferPage extends StatefulWidget {
  const PremiumOfferPage({super.key});

  @override
  State<PremiumOfferPage> createState() => _PremiumOfferPageState();
}

class _PremiumOfferPageState extends State<PremiumOfferPage> {
  Timer? _notNowTimer;
  bool _showNotNow = false;
  String _selectedPlan = 'yearly';

  static const List<String> _features = [
    'Guided meditations',
    'Sleep stories',
    'Daily mindfulness practices',
    'Exclusive soundscapes',
    'Track your progress',
  ];

  @override
  void initState() {
    super.initState();
    _notNowTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showNotNow = true;
      });
    });
  }

  @override
  void dispose() {
    _notNowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final titleSize = (shortestSide * 0.068).clamp(27.0, 34.0).toDouble();
    final bodySize = (shortestSide * 0.04).clamp(15.5, 18.0).toDouble();

    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.chevron_left_rounded),
                color: const Color(0xFF263746),
                iconSize: 32,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 38,
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: _showNotNow ? 1 : 0,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                child: TextButton(
                  onPressed: _showNotNow
                      ? () {
                          if (Supabase.instance.client.auth.currentSession !=
                              null) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacement(
                              _fadeRoute(
                                Builder(
                                  builder: (authContext) => AuthPage(
                                    startWithSignUp: true,
                                    onExplore: () => Navigator.of(authContext)
                                        .push(_fadeRoute(const WelcomePage())),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF263746),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(74, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (size.height * 0.035).clamp(24.0, 38.0).toDouble()),
          Text(
            'Continue Your Journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF263746),
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock your full potential with\nSeren Premium.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF53616B),
              fontSize: bodySize,
              fontWeight: FontWeight.w500,
              height: 1.28,
            ),
          ),
          SizedBox(height: (size.height * 0.035).clamp(24.0, 34.0).toDouble()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 295),
              child: Column(
                children: _features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PremiumFeatureRow(label: feature),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: (size.height * 0.035).clamp(24.0, 34.0).toDouble()),
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  title: 'Monthly',
                  price: r'$9.99',
                  subtitle: 'per month',
                  isSelected: _selectedPlan == 'monthly',
                  onTap: () {
                    setState(() {
                      _selectedPlan = 'monthly';
                    });
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PlanCard(
                  title: 'Yearly',
                  price: r'$59.99',
                  subtitle: r'$4.99 per month',
                  footer: 'Save 50%',
                  isSelected: _selectedPlan == 'yearly',
                  onTap: () {
                    setState(() {
                      _selectedPlan = 'yearly';
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: (size.height * 0.04).clamp(26.0, 42.0).toDouble()),
          AppPrimaryButton(
            label: 'Start Your Free 7-Day Trial',
            onPressed: () {},
          ),
          const SizedBox(height: 24),
          Text(
            'Cancel anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF53616B),
              fontSize: bodySize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: (size.height * 0.03).clamp(22.0, 34.0).toDouble()),
        ],
      ),
    );
  }
}

class _PremiumFeatureRow extends StatelessWidget {
  const _PremiumFeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 23,
          height: 23,
          decoration: const BoxDecoration(
            color: Color(0xFF496677),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF53616B),
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.footer,
  });

  final String title;
  final String price;
  final String subtitle;
  final String? footer;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final cardHeight = (shortestSide * 0.43).clamp(166.0, 184.0).toDouble();
    final horizontalPadding = (shortestSide * 0.045)
        .clamp(16.0, 22.0)
        .toDouble();
    final verticalPadding = (shortestSide * 0.034).clamp(12.0, 16.0).toDouble();
    final titleSize = (shortestSide * 0.04).clamp(15.0, 17.0).toDouble();
    final priceSize = (shortestSide * 0.06).clamp(23.0, 27.0).toDouble();
    final detailSize = (shortestSide * 0.032).clamp(12.0, 13.5).toDouble();

    return Material(
      color: isSelected ? const Color(0xFFEAF1F5) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: cardHeight,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6F8796)
                  : const Color(0xFFDADDDD),
              width: isSelected ? 1.6 : 1.1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                alignment: Alignment.topLeft,
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: const Color(0xFF53616B),
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        price,
                        style: TextStyle(
                          color: const Color(0xFF263746),
                          fontSize: priceSize,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFF53616B),
                          fontSize: detailSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          footer!,
                          style: TextStyle(
                            color: const Color(0xFF53616B),
                            fontSize: detailSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;
  _SoundItem _selectedSound = _sounds.first;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingAsset;

  static const List<_SoundItem> _sounds = [
    _SoundItem(
      title: 'Ocean Waves',
      subtitle: 'Calm',
      description: 'A steady rhythm to calm the mind.',
      imagePath: 'assets/cover_iamge/sea_waves.png',
      audioPath: 'assets/audio/sea_water.mp3',
    ),
    _SoundItem(
      title: 'Forest Rain',
      subtitle: 'Relax',
      description: 'Find stillness in the sound of rain.',
      imagePath: 'assets/cover_iamge/forest_rain.png',
      audioPath: 'assets/audio/forest_rain.mp3',
    ),
    _SoundItem(
      title: 'White Noise',
      subtitle: 'Focus',
      description: 'A gentle backdrop for a clearer mind.',
      imagePath: 'assets/cover_iamge/white_noise.png',
      audioPath: 'assets/audio/white_noise.mp3',
    ),
    _SoundItem(
      title: 'Peaceful Piano',
      subtitle: 'Ambient',
      description: 'Soft melodies for a quiet moment.',
      imagePath: 'assets/cover_iamge/piano.png',
      audioPath: 'assets/audio/peaceful_piano.mp3',
    ),
    _SoundItem(
      title: 'Night Ambience',
      subtitle: 'Sleep',
      description: 'Ease into rest with the sounds of night.',
      imagePath: 'assets/cover_iamge/night_ambiance_cover_image.png',
      audioPath: 'assets/audio/night_ambiance.mp3',
    ),
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboardPage(
        sound: _selectedSound,
        isPlaying: _playingAsset == _selectedSound.audioPath,
        onPlayToggle: () => _togglePlayback(_selectedSound),
        onLibraryTap: () => _selectTab(1),
      ),
      _LibraryPage(
        sounds: _sounds,
        playingAsset: _playingAsset,
        onSoundTap: _togglePlayback,
        onSoundOpen: _openSound,
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_selectedIndex],
      bottomNavigationBar: _SerenBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSound(_SoundItem sound) {
    unawaited(_audioPlayer.pause());
    setState(() {
      _selectedSound = sound;
      _playingAsset = null;
      _selectedIndex = 0;
    });
  }

  Future<void> _togglePlayback(_SoundItem sound) async {
    if (_playingAsset == sound.audioPath) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _playingAsset = null);
      return;
    }
    try {
      await _audioPlayer.setAsset(sound.audioPath);
      await _audioPlayer.setLoopMode(LoopMode.one);
      if (mounted) setState(() => _playingAsset = sound.audioPath);
      unawaited(_audioPlayer.play());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to play this sound.')),
        );
      }
    }
  }
}

class _SoundItem {
  const _SoundItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.audioPath,
  });

  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final String audioPath;
}

class _HomeDashboardPage extends StatefulWidget {
  const _HomeDashboardPage({
    required this.sound,
    required this.isPlaying,
    required this.onPlayToggle,
    required this.onLibraryTap,
  });

  final _SoundItem sound;
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final VoidCallback onLibraryTap;

  @override
  State<_HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<_HomeDashboardPage>
    with SingleTickerProviderStateMixin {
  static const String _videoPath = 'assets/Background_video/home_silk_loop.mp4';
  static const String _stillPath = 'assets/Background_video/home_still.jpg';
  late final VideoPlayerController _videoController;
  late final AnimationController _cameraMotion;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _cameraMotion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _videoController = VideoPlayerController.asset(_videoPath);
    unawaited(_initializeVideo());
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();
      await _videoController.setVolume(0);
      await _videoController.setLooping(true);
      await _videoController.setPlaybackSpeed(0.7);
      if (!mounted) return;
      setState(() => _videoReady = true);
      if (widget.isPlaying) {
        _cameraMotion.repeat();
        await _videoController.play();
      }
    } catch (error) {
      debugPrint('Home background video failed: $error');
      // Keep the first-frame image visible if video is unavailable.
    }
  }

  @override
  void didUpdateWidget(covariant _HomeDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_videoReady && oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _cameraMotion.repeat();
        unawaited(_videoController.play());
      } else {
        _cameraMotion.stop();
        unawaited(_videoController.pause());
      }
    }
  }

  @override
  void dispose() {
    _cameraMotion.dispose();
    unawaited(_videoController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final horizontalPadding = AppLayout.horizontalPadding(context);
    final titleSize = (shortestSide * 0.135).clamp(46.0, 66.0).toDouble();
    final circleSize = (shortestSide * 0.45).clamp(162.0, 218.0).toDouble();

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_stillPath, fit: BoxFit.cover),
        if (_videoReady)
          AnimatedBuilder(
            animation: _cameraMotion,
            builder: (context, child) {
              final phase = _cameraMotion.value * 2 * math.pi;
              return Transform.translate(
                offset: Offset(14 * math.sin(phase), 8 * math.cos(phase)),
                child: Transform.scale(
                  scale: 1.06 + 0.015 * math.sin(phase),
                  child: child,
                ),
              );
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
        const DecoratedBox(decoration: BoxDecoration(color: Color(0x30000000))),
        SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    126,
                  ),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: widget.onLibraryTap,
                          icon: const Icon(Icons.favorite_border_rounded),
                          color: Colors.white,
                          iconSize: 32,
                        ),
                      ),
                      SizedBox(height: (size.height * 0.026).clamp(14.0, 28.0)),
                      Text(
                        'Seren',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Georgia',
                          fontSize: titleSize,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'A calmer you\nfor a brighter tomorrow.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          height: 1.24,
                        ),
                      ),
                      SizedBox(height: (size.height * 0.035).clamp(20.0, 34.0)),
                      SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: Image.asset(
                                widget.sound.imagePath,
                                width: circleSize - 8,
                                height: circleSize - 8,
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.sound.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.sound.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _RoundPlayButton(
                        isPlaying: widget.isPlaying,
                        onPressed: widget.onPlayToggle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage({
    required this.sounds,
    required this.playingAsset,
    required this.onSoundTap,
    required this.onSoundOpen,
  });

  final List<_SoundItem> sounds;
  final String? playingAsset;
  final ValueChanged<_SoundItem> onSoundTap;
  final ValueChanged<_SoundItem> onSoundOpen;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 38),
          const Text(
            'Your Favourites',
            style: TextStyle(
              color: Color(0xFF263746),
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quick access to what you love.',
            style: TextStyle(color: Color(0xFF6D7D8A), fontSize: 16),
          ),
          const SizedBox(height: 28),
          ...sounds
              .take(5)
              .map(
                (sound) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _LibrarySoundRow(
                    sound: sound,
                    isPlaying: playingAsset == sound.audioPath,
                    onPlayTap: () => onSoundTap(sound),
                    onOpen: () => onSoundOpen(sound),
                  ),
                ),
              ),
          const SizedBox(height: 132),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _displayName;
  String? _signOutError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) {
        setState(() => _displayName = row?['display_name'] as String?);
      }
    } catch (_) {
      // Auth metadata still gives the account a name before migrations are run.
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (mounted) setState(() => _signOutError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _signOutError = 'Could not sign out. Please try again.');
      }
    }
  }

  static const String _branchPath = 'assets/icons/branch.png';

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name =
        _displayName ??
        user?.userMetadata?['display_name'] as String? ??
        user?.email?.split('@').first ??
        'Your account';
    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 44),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE4EEF5),
                ),
                padding: const EdgeInsets.all(15),
                child: Image.asset(_branchPath),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Color(0xFF263746),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Color(0xFF6D7D8A), fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _PlanSummaryCard(
            onUpgrade: () {
              Navigator.of(context).push(_fadeRoute(const PremiumOfferPage()));
            },
          ),
          const SizedBox(height: 26),
          const _ProfileMenuItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
          ),
          const _ProfileMenuItem(
            icon: Icons.notifications_rounded,
            label: 'Reminders',
          ),
          const _ProfileMenuItem(
            icon: Icons.help_rounded,
            label: 'Help & Support',
          ),
          const _ProfileMenuItem(icon: Icons.info_rounded, label: 'About'),
          const SizedBox(height: 14),
          _SignOutRow(onTap: _signOut),
          if (_signOutError != null)
            Text(
              _signOutError!,
              style: const TextStyle(color: Color(0xFFAC4A4A)),
            ),
          const SizedBox(height: 132),
        ],
      ),
    );
  }
}

class _SerenBottomNav extends StatelessWidget {
  const _SerenBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.library_music_rounded, label: 'Library'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppLayout.horizontalPadding(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 88,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F263746),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.58),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(_items.length, (index) {
                          final item = _items[index];
                          final selected = index == selectedIndex;
                          return _BottomNavButton(
                            item: item,
                            isSelected: selected,
                            onTap: () => onSelected(index),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF263746)
        : const Color(0xFF7890A4);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundPlayButton extends StatelessWidget {
  const _RoundPlayButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263746),
          elevation: 12,
          shadowColor: const Color(0x44374747),
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 48,
        ),
      ),
    );
  }
}

class _LibrarySoundRow extends StatelessWidget {
  const _LibrarySoundRow({
    required this.sound,
    required this.isPlaying,
    required this.onPlayTap,
    required this.onOpen,
  });

  final _SoundItem sound;
  final bool isPlaying;
  final VoidCallback onPlayTap;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: _SoftCard(
        child: Row(
          children: [
            _SoundArtwork(sound: sound, size: 68),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.title,
                    style: const TextStyle(
                      color: Color(0xFF263746),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound.subtitle == 'Sleep' ? 'Sleep' : 'Nature',
                    style: const TextStyle(
                      color: Color(0xFF6D7D8A),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            _TinyPlayButton(isPlaying: isPlaying, onPressed: onPlayTap),
          ],
        ),
      ),
    );
  }
}

class _SoundArtwork extends StatelessWidget {
  const _SoundArtwork({required this.sound, required this.size});

  final _SoundItem sound;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        sound.imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _TinyPlayButton extends StatelessWidget {
  const _TinyPlayButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: isPlaying ? 'Pause' : 'Play',
      icon: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: const Color(0xFF31536B),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Color(0xFF7890A4)),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Plan',
                      style: TextStyle(
                        color: Color(0xFF263746),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Access to core sounds and features.',
                      style: TextStyle(color: Color(0xFF6D7D8A), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3E49),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text('Upgrade to Premium'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 15,
        backgroundColor: const Color(0xFF8BA8BC),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF53616B),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF7890A4),
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  const _SignOutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFFE66067),
            child: Icon(Icons.logout_rounded, color: Colors.white, size: 18),
          ),
          SizedBox(width: 16),
          Text(
            'Sign Out',
            style: TextStyle(
              color: Color(0xFFE66067),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
