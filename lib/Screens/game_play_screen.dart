import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Services/progress_service.dart';
import 'package:firebase_auth/firebase_auth.dart';




class GamePlayScreen extends StatefulWidget {
  final int level; // 1, 2, 3
  final int game;  // 1..n (we’ll use 1 for addition)

  const GamePlayScreen({
    super.key,
    required this.level,
    required this.game,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  // --- Game config ---
  static const int totalQuestions = 5;

  int get secondsPerQuestion {
    switch (widget.level) {
      case 1:
        return 45;
      case 2:
        return 30;
      case 3:
        return 15;
      default:
        return 30;
    }
  }

  // --- State ---
  final Random rng = Random();
  Timer? timer;

  int questionIndex = 1; // 1..5
  int remainingSeconds = 0;

  int score = 0;
  String answer = '';

  late int a;
  late int b;

  int get correctAnswer => a + b;

  int incorrect = 0;
  bool _savingResult = false;

  final List<Map<String, dynamic>> questionLogs = [];
  DateTime? questionStartTime;
  DateTime? gameStartTime;


  @override
  void initState() {
    super.initState();
    _startNewQuestion();
    gameStartTime = DateTime.now();

  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startNewQuestion() {
    timer?.cancel();

    // Random numbers 1..12
    a = rng.nextInt(12) + 1;
    b = rng.nextInt(12) + 1;

    answer = '';
    remainingSeconds = secondsPerQuestion;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        remainingSeconds--;
      });

      if (remainingSeconds <= 0) {
        timer?.cancel();
        _handleTimeUp();
      }
    });

    setState(() {});

    questionStartTime = DateTime.now();

  }

  void _handleTimeUp() {
    setState(() => incorrect += 1);
    _goToNextQuestion(showMessage: "Time's up!");
  }


  void _pressDigit(int d) {
    setState(() {
      if (answer.length < 6) {
        answer += d.toString();
      }
    });
  }

  void _backspace() {
    setState(() {
      if (answer.isNotEmpty) {
        answer = answer.substring(0, answer.length - 1);
      }
    });
  }

  void _enter() {
    final int? parsed = int.tryParse(answer);
    final bool isCorrect = (parsed != null && parsed == correctAnswer);

    if (isCorrect) {
      setState(() => score += 1);
      _goToNextQuestion(showMessage: 'Correct! +1');
    } else {
      setState(() => incorrect += 1);
      _goToNextQuestion(showMessage: 'Incorrect');
    }
  }


  void _goToNextQuestion({required String showMessage}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(showMessage),
        duration: const Duration(milliseconds: 700),
      ),
    );

    // Stop timer for this question
    timer?.cancel();

    if (questionIndex >= totalQuestions) {
      _finishGame();
      return;
    }

    setState(() {
      questionIndex++;
    });

    _startNewQuestion();
  }

  Future<void> _finishGame() async {

    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('FINISH GAME uid=$uid score=$score incorrect=$incorrect level=${widget.level}');


    timer?.cancel();

    if (_savingResult) return;
    setState(() => _savingResult = true);

    // Pick a stable gameId (important for dashboard grouping)
    final String gameId = 'timed_addition'; // since game 1 is your addition game

    try {
      debugPrint('Saving progress…');
      await ProgressService().recordGameResult(
        gameId: gameId,
        correct: score,
        incorrect: incorrect,
        level: widget.level,
      );
      debugPrint('Saved progress ✅');
    } catch (e) {
      debugPrint('SAVE FAILED ❌ $e');
      // Don’t block the user – but do show the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save progress: $e')),
        );
      }
    }

    if (!mounted) return;

    setState(() => _savingResult = false);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game finished'),
        content: Text('You scored $score / $totalQuestions'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit game screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  void _confirmExit() {
    timer?.cancel();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit game?'),
        content: const Text('Your current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              _startNewQuestion(); // resume (restart current question)
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // leave screen
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int secs) {
    if (secs < 0) secs = 0;
    final int m = secs ~/ 60;
    final int s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String timeText = _formatTime(remainingSeconds);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---------- TOP BAR ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // X button to exit
                  IconButton(
                    onPressed: _confirmExit,
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),

                  // Timer pill
                  Expanded(
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Score box (top right)
                  Container(
                    width: 64,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      border: Border.all(color: Colors.black45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ---------- GAME AREA ----------
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Question $questionIndex / $totalQuestions',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '$a + $b = ?',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black38),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            answer.isEmpty ? ' ' : answer,
                            style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- KEYPAD ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: _Keypad(
                onDigit: _pressDigit,
                onBackspace: _backspace,
                onEnter: _enter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(int digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onEnter;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    // 2 rows of 6 buttons like your mock-up
    return Column(
      children: [
        Row(
          children: [
            _key('1', onTap: () => onDigit(1)),
            _key('2', onTap: () => onDigit(2)),
            _key('3', onTap: () => onDigit(3)),
            _key('4', onTap: () => onDigit(4)),
            _key('5', onTap: () => onDigit(5)),
            _key('6', onTap: () => onDigit(6)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _key('7', onTap: () => onDigit(7)),
            _key('8', onTap: () => onDigit(8)),
            _key('9', onTap: () => onDigit(9)),
            _key('0', onTap: () => onDigit(0)),
            _key('⌫', onTap: onBackspace),
            _key('↵', onTap: onEnter),
          ],
        ),
      ],
    );
  }

  Widget _key(String label, {required VoidCallback onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade600),
              foregroundColor: Colors.black,
              backgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
