import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Services/game_log_service.dart';

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

class _Q {
  final String id;
  final int index; // 1..5 (original question number)
  final int a;
  final int b;

  const _Q({
    required this.id,
    required this.index,
    required this.a,
    required this.b,
  });
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

  bool _ready = false;

  final List<Map<String, dynamic>> questionLogs = [];
  DateTime? questionStartTime;
  DateTime? gameStartTime;

  static const String _gameId = 'timed_addition';
  static const String _gameName = 'Timed Addition';

  String? _logId;
  final List<Map<String, dynamic>> _questionLogs = [];
  DateTime? _questionStart;
  bool _saving = false;

  final List<_Q> _queue = [];
  _Q? _current;

  int completedCorrectly = 0; // out of totalQuestions
  int attempts = 0; // total attempts (including repeats)

  final Map<String, int> _attemptCountByQuestionId = {}; // qid -> attempts



  @override
  void initState() {
    super.initState();
    _initLogAndStart();
  }

  Future<void> _initLogAndStart() async {
    _ready = false;

    try {
      _logId = await GameLogService().createLog(
        gameId: _gameId,
        gameName: _gameName,
        level: widget.level,
        totalQuestions: totalQuestions,
      );
    } catch (e) {
      debugPrint('Failed to create game log: $e');
    }

    _queue.clear();
    score = 0;
    incorrect = 0;

    _questionLogs.clear();
    _attemptCountByQuestionId.clear();

    for (int i = 0; i < totalQuestions; i++) {
      final qa = rng.nextInt(12) + 1;
      final qb = rng.nextInt(12) + 1;
      _queue.add(_Q(id: 'q${i + 1}', index: i + 1, a: qa, b: qb));
    }

    _current = _queue.removeAt(0);

    setState(() => _ready = true);
    _startNewQuestion();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startNewQuestion() {
    timer?.cancel();

    final q = _current;
    if (q == null) return;

    a = q.a;
    b = q.b;

    answer = '';
    remainingSeconds = secondsPerQuestion;
    _questionStart = DateTime.now();

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
  }

  Future<void> _submitAttempt({
    required bool isCorrect,
    required int? userAnswer,
    required bool timedOut,
    required String snack,
  }) async {
    final q = _current;
    if (q == null) return;

    timer?.cancel();

    // Attempt number for this specific question
    final attemptNo = (_attemptCountByQuestionId[q.id] ?? 0) + 1;
    _attemptCountByQuestionId[q.id] = attemptNo;

    final now = DateTime.now();
    final timeTakenMs = _questionStart == null
        ? 0
        : now.difference(_questionStart!).inMilliseconds;

    // Track counters
    setState(() {
      attempts += 1;

      if (isCorrect) {
        score += 1;
        completedCorrectly += 1;
      } else {
        incorrect += 1;
      }
    });

    // Log attempt
    _questionLogs.add({
      'questionId': q.id,
      'questionIndex': q.index, // IMPORTANT: original question number
      'attemptNo': attemptNo,
      'a': q.a,
      'b': q.b,
      'correctAnswer': q.a + q.b,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeTakenMs': timeTakenMs,
      'timedOut': timedOut,
    });

    await _saveQuestionUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snack), duration: const Duration(milliseconds: 700)),
      );
    }

    // If incorrect, re-add this same question to end
    if (!isCorrect) {
      _queue.add(q);
    }

    // Finished when all 5 are eventually correct
    if (completedCorrectly >= totalQuestions) {
      await _finishGame();
      return;
    }

    // Move to next question
    if (_queue.isEmpty) {
      // This shouldn't happen unless something goes wrong
      await _finishGame();
      return;
    }

    setState(() {
      _current = _queue.removeAt(0);
    });

    _startNewQuestion();
  }



  void _handleTimeUp() {
    _submitAttempt(
      isCorrect: false,
      userAnswer: null,
      timedOut: true,
      snack: "Time's up!",
    );
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

    _submitAttempt(
      isCorrect: isCorrect,
      userAnswer: parsed,
      timedOut: false,
      snack: isCorrect ? 'Correct! +1' : 'Incorrect',
    );
  }


  Future<void> _saveQuestionUpdate() async {
    final logId = _logId;
    if (logId == null) return; // logging not available

    if (_saving) return;
    _saving = true;

    try {
      await GameLogService().updateAfterQuestion(
        logId: logId,
        questionIndex: completedCorrectly + 1,
        correct: score,
        incorrect: incorrect,
        allQuestionsSoFar: List<Map<String, dynamic>>.from(_questionLogs),
      );


    } catch (e) {
      debugPrint('Failed to update game log: $e');
    } finally {
      _saving = false;
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
    timer?.cancel();

    final logId = _logId;
    if (logId != null) {
      try {
        await GameLogService().markCompleted(
          logId: logId,
          correct: score,
          incorrect: incorrect,
        );
      } catch (e) {
        debugPrint('Failed to mark completed: $e');
      }
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game finished'),
        content: Text('You scored $score / $totalQuestions'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
            onPressed: () async {
              Navigator.pop(context); // close dialog

              final logId = _logId;
              if (logId != null) {
                try {
                  await GameLogService().markAbandoned(
                    logId: logId,
                    correct: score,
                    incorrect: incorrect,
                  );
                } catch (e) {
                  debugPrint('Failed to mark abandoned: $e');
                }
              }

              if (mounted) Navigator.pop(context); // leave screen
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

    if (!_ready || _current == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final q = _current!;
    final displayIndex = q.index;


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
                          'Question $displayIndex / $totalQuestions',
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
