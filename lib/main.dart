import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Frisbee Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const DogGameScreen(),
        '/blank': (context) => const MaycieScreen(),
      },
      initialRoute: '/',
    );
  }
}

/// A blank screen
class MaycieScreen extends StatelessWidget {
  const MaycieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Me'),
        backgroundColor: Colors.blueAccent,
      ),
body: Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Center(
        child: CircleAvatar(
          radius: 60,
          backgroundImage: AssetImage('assets/profile.jpg'),
        ),
      ),
      SizedBox(height: 20),
      Center(
        child: Text(
          'Your Name',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      SizedBox(height: 10),
      Center(
        child: Text(
          'Flutter Developer | Tech Enthusiast',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
      SizedBox(height: 20),
      Text(
        'About Me:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),
      Text(
        'I am a passionate Flutter developer who enjoys building beautiful and functional applications. '
        'With experience in UI/UX design, I love to craft seamless user experiences.',
        style: TextStyle(fontSize: 16),
      ),
      SizedBox(height: 20),
      Text(
        'Contact Me:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),
      Row(
        children: [
          Icon(Icons.email, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('your.email@example.com'),
        ],
      ),
      SizedBox(height: 10),
      Row(
        children: [
          Icon(Icons.link, color: Colors.blueAccent),
          SizedBox(width: 10),
          Text('yourwebsite.com'),
        ],
      ),
    ],
  ),
),
    );
  }
}




//------------------------------------------------------------------------------------------------
class DogGameScreen extends StatefulWidget {
  const DogGameScreen({super.key});

  @override
  State<DogGameScreen> createState() => _DogGameScreenState();
}

class _DogGameScreenState extends State<DogGameScreen>
    with SingleTickerProviderStateMixin {
  //Focus node for keyboard input
  final FocusNode _focusNode = FocusNode();

  //Score for how long the frisbee stayed in the air
  int _score = 0;

  //Angle of the throw (in degrees)
  double _throwAngle = 0;

  //charging the throw
  bool _isCharging = false;

  //the power of the charge
  double _chargePower = 0.0;
  final double _maxCharge = 100.0;

  //Timer measuring flight time
  Timer? _frisbeeTimer;
  int _frisbeeTime = 0; // milliseconds

  //Animation for the frisbee arc
  late AnimationController _flightController;
  late Animation<double> _flightAnim;

  //Is frisbee flying
  bool _isFlying = false;

  //Frisbee initial position
  double _frisbeeX = 59;
  double _frisbeeY = 435;

  //dog info
  double _dogX = 500;
  double _dogY = 407;
  final double _dogWidth = 100;
  final double _dogHeight = 100;
  bool _dogFacingRight = true; // flip horizontally if facing left

  // Start positions each throw
  double _frisbeeXStart = 59;
  double _frisbeeYStart = 435;
  double _dogStartX = 500;
  double _dogStartY = 407;

  //Screen size
  late double _screenWidth;
  late double _screenHeight;

  //Arc parameters
  double _dx = 0;
  double _dy = 0;
  double _arcHeight = 0;

  //Dog speed horizontally (pixels per frame)
  double _dogSpeed = 10.0;

  @override
  void initState() {
    super.initState();

    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    //
    _flightAnim = Tween<double>(begin: 0, end: 1).animate(_flightController)
      ..addListener(() {
        setState(() {
          final t = _flightAnim.value;

          final x0 = _frisbeeXStart;
          final y0 = _frisbeeYStart;

          final xPos = x0 + _dx * t;
          final yPos = y0 + _dy * t - _arcHeight * 4 * t * (1 - t);
          _frisbeeX = xPos;
          _frisbeeY = yPos;

        
          final dogGroundY = _screenHeight - 120 - _dogHeight;
          _dogY = dogGroundY;

          //decide direction dog is facing an move
          if ((_dogX - xPos).abs() > 2) {
            if (_dogX < xPos) {
              //dog moves right
              _dogFacingRight = true;
              _dogX += _dogSpeed;
              if (_dogX > xPos) {
                _dogX = xPos;
              }
            } else {
              //dog moves left
              _dogFacingRight = false;
              _dogX -= _dogSpeed;
              if (_dogX < xPos) {
                _dogX = xPos;
              }
            }
          }

          //collision detection
          final dogCenterX = _dogX + _dogWidth / 2;
          final dogCenterY = _dogY + _dogHeight / 2;
          final frisbeeCenterX = _frisbeeX + 15;
          final frisbeeCenterY = _frisbeeY + 15;

          final dx = dogCenterX - frisbeeCenterX;
          final dy = dogCenterY - frisbeeCenterY;
          final dist = math.sqrt(dx * dx + dy * dy);

          if (dist < 40) {
            //dog catches
            _flightController.stop();
            _dogCatchesFrisbee();
          }
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dogCatchesFrisbee();
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      final size = MediaQuery.of(context).size;
      _screenWidth = size.width;
      _screenHeight = size.height;

      final dogGroundY = _screenHeight - 120 - _dogHeight;
      _dogY = dogGroundY;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _frisbeeTimer?.cancel();
    _flightController.dispose();
    super.dispose();
  }

  void _startFrisbeeTimer() {
    _frisbeeTime = 0;
    _frisbeeTimer?.cancel();
    _frisbeeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        _frisbeeTime += 100;
      },
    );
  }

  void _dogCatchesFrisbee() {
    _frisbeeTimer?.cancel();
    // Score is # of full seconds airborne
    final seconds = (_frisbeeTime ~/ 10);
    _score += seconds;
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _isFlying = false;
      _chargePower = 0;
      _frisbeeTime = 0;
      _flightController.stop();

      //reset frisbee(thats actually a ball)
      _frisbeeX = 59;
      _frisbeeY = 435;
      _frisbeeXStart = 59;
      _frisbeeYStart = 435;

      //reset dog
      _dogX = 500;
      final dogGroundY = _screenHeight - 120 - _dogHeight;
      _dogY = dogGroundY;
      _dogStartX = 500;
      _dogStartY = dogGroundY;
      _dogFacingRight = true;
    });
  }

  void _throwFrisbee() {
    if (_isFlying) return;

    _isFlying = true;
    _startFrisbeeTimer();

    //Mark start positioms
    _frisbeeXStart = _frisbeeX;
    _frisbeeYStart = _frisbeeY;
    _dogStartX = _dogX;
    _dogStartY = _dogY;

    //convert angle to radians
    final radians = (_throwAngle * math.pi) / 180.0;

    //limit by screen size
    final maxDist = (_screenWidth - 200).clamp(0, double.infinity);
    final dist = (_chargePower / _maxCharge) * maxDist;

    _dx = math.cos(radians) * dist;
    _dy = -math.sin(radians) * dist;

    _arcHeight = dist * 0.3;
    if (_arcHeight < 30) {
      _arcHeight = 30;
    }

    final flightDurationSec = 1 + (dist / maxDist);
    _flightController.duration =
        Duration(milliseconds: (flightDurationSec * 1000).round());

    _flightController.forward(from: 0);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _throwAngle -= 5;
        });
      } else if (key == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _throwAngle += 5;
        });
      } else if (key == LogicalKeyboardKey.space && !_isCharging && !_isFlying) {
        _isCharging = true;
        _startCharging();
      }
    } else if (event is KeyUpEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.space && _isCharging) {
        _isCharging = false;
        _throwFrisbee();
      }
    }
  }

  Future<void> _startCharging() async {
    while (_isCharging && mounted) {
      setState(() {
        _chargePower += 1;
        if (_chargePower > _maxCharge) {
          _chargePower = _maxCharge;
        }
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog Frisbee Game'),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _screenWidth = constraints.maxWidth;
            _screenHeight = constraints.maxHeight;

            const double grassHeight = 120;

            return Stack(
              children: [
                //background
                Positioned.fill(
                  child: Image.asset(
                    'assets/background.jpg',
                    fit: BoxFit.cover,
                  ),
                ),

                //grass
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: grassHeight,
                    child: Image.asset(
                      'assets/grass.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                //overlay
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Score: $_score',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Angle: $_throwAngle°',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCharging
                            ? 'Charging... power: ${_chargePower.toStringAsFixed(0)}'
                            : 'Press and hold SPACE to charge throw',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/blank');
                        },
                        child: const Text('Go to other Screen'),
                      ),
                    ],
                  ),
                ),

                //dude at the bottom
                Positioned(
                  bottom: grassHeight - 20,
                  left: 40,
                  child: Image.asset(
                    'assets/manthrow.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),

                // Dog (walks horizontally flips if facing left)
                Positioned(
                  left: _dogX,
                  top: _dogY,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: _dogFacingRight
                        ? Matrix4.identity()
                        : Matrix4.diagonal3Values(-1, 1, 1),
                    child: Image.asset(
                      'assets/dogrun.gif',
                      width: _dogWidth,
                      height: _dogHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // frisbee(a ball now)
                Positioned(
                  left: _frisbeeX,
                  top: _frisbeeY,
                  child: Image.asset(
                    'assets/ball.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),

              ],
            );
          },
        ),
      ),
    );
  }
}
