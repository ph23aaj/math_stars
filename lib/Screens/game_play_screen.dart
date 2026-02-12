import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Services/game_log_service.dart';

class GamePlayScreen extends StatefulWidget {
  final int level; // 1, 2, 3
  final int game;  // 1 = addition, 2 = subtraction

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
  final int index; // original question number 1..5
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

  // Game mapping: 1=addition, 2=subtraction, 3=multiplication
  bool get _isAddition => widget.game == 1;
  bool get _isSubtraction => widget.game == 2;
  bool get _isMultiplication => widget.game == 3;

  String get _gameId {
    if (_isSubtraction) return 'timed_subtraction';
    if (_isMultiplication) return 'timed_multiplication';
    return 'timed_addition';
  }

  String get _gameName {
    if (_isSubtraction) return 'Timed Subtraction';
    if (_isMultiplication) return 'Timed Multiplication';
    return 'Timed Addition';
  }

  String get _opSymbol {
    if (_isSubtraction) return '-';
    if (_isMultiplication) return '×';
    return '+';
  }

  int _computeAnswer(int a, int b) {
    if (_isSubtraction) return a - b;
    if (_isMultiplication) return a * b;
    return a + b;
  }


  final Random rng = Random();
  Timer? timer;

  bool _ready = false;

  int remainingSeconds = 0;
  String answer = '';

  // Current displayed values
  int a = 1;
  int b = 1;
  int get correctAnswer => _computeAnswer(a, b);

  // Counters
  int score = 0; // number solved correctly (final solves)
  int incorrect = 0; // number of incorrect attempts
  int completedCorrectly = 0; // out of totalQuestions (base questions)

  // Queue repeats wrong questions at end
  final List<_Q> _queue = [];
  _Q? _current;

  // Timing/logging
  DateTime? _questionStart;
  String? _logId;
  bool _saving = false;
  final List<Map<String, dynamic>> _questionLogs = [];
  final Map<String, int> _attemptCountByQuestionId = {};

  @override
  void initState() {
    super.initState();
    _initLogAndStart();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _initLogAndStart() async {
    setState(() => _ready = false);

    // Create a partial log at the start (so abandoned sessions exist)
    try {
      _logId = await GameLogService().createLog(
        gameId: _gameId,
        gameName: _gameName,
        level: widget.level,
        totalQuestions: totalQuestions,
      );
    } catch (e) {
      debugPrint('Failed to create game log: $e');
      _logId = null;
    }

    // Reset state
    timer?.cancel();
    remainingSeconds = secondsPerQuestion;
    answer = '';
    score = 0;
    incorrect = 0;
    completedCorrectly = 0;

    _queue.clear();
    _current = null;

    _questionLogs.clear();
    _attemptCountByQuestionId.clear();

    // Generate base questions
    for (int i = 0; i < totalQuestions; i++) {
      int qa;
      int qb;

      if (_isSubtraction) {
        // 1..24, keep non-negative (a >= b)
        qa = rng.nextInt(24) + 1;
        qb = rng.nextInt(24) + 1;
        if (qb > qa) {
          final tmp = qa;
          qa = qb;
          qb = tmp;
        }
      } else if (_isMultiplication) {
        // Multiplication 1..12
        qa = rng.nextInt(12) + 1;
        qb = rng.nextInt(12) + 1;
      } else {
        // Addition 1..12
        qa = rng.nextInt(12) + 1;
        qb = rng.nextInt(12) + 1;
      }

      _queue.add(_Q(id: 'q${i + 1}', index: i + 1, a: qa, b: qb));
    }

    _current = _queue.removeAt(0);

    setState(() => _ready = true);
    _startNewQuestion();
  }

  void _startNewQuestion() {
    timer?.cancel();

    final q = _current;
    if (q == null) return;

    // Load question numbers into display variables
    a = q.a;
    b = q.b;

    answer = '';
    remainingSeconds = secondsPerQuestion;
    _questionStart = DateTime.now();

    // Start countdown
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() => remainingSeconds--);

      if (remainingSeconds <= 0) {
        timer?.cancel();
        _handleTimeUp();
      }
    });

    setState(() {}); // refresh UI
  }

  void _pressDigit(int d) {
    setState(() {
      if (answer.length < 6) answer += d.toString();
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

  void _handleTimeUp() {
    _submitAttempt(
      isCorrect: false,
      userAnswer: null,
      timedOut: true,
      snack: "Time's up!",
    );
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

    // Attempt number for this specific base question
    final attemptNo = (_attemptCountByQuestionId[q.id] ?? 0) + 1;
    _attemptCountByQuestionId[q.id] = attemptNo;

    final now = DateTime.now();
    final timeTakenMs = _questionStart == null
        ? 0
        : now.difference(_questionStart!).inMilliseconds;

    // Update counters
    if (isCorrect) {
      score += 1;
      completedCorrectly += 1;
    } else {
      incorrect += 1;
    }

    // Add attempt log entry
    _questionLogs.add({
      'questionId': q.id,
      'questionIndex': q.index, // original question number (1..5)
      'attemptNo': attemptNo,
      'a': q.a,
      'b': q.b,
      'operator': _opSymbol,
      'correctAnswer': _computeAnswer(q.a, q.b),
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeTakenMs': timeTakenMs,
      'timedOut': timedOut,
    });

    await _saveQuestionUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snack),
          duration: const Duration(milliseconds: 700),
        ),
      );
    }

    // If wrong, repeat it later by adding to end of queue
    if (!isCorrect) {
      _queue.add(q);
    }

    // Finish once all 5 base questions have been solved correctly
    if (completedCorrectly >= totalQuestions) {
      await _finishGame();
      return;
    }

    // Next question
    if (_queue.isEmpty) {
      await _finishGame();
      return;
    }
    _current = _queue.removeAt(0);

    setState(() {});
    _startNewQuestion();
  }

  Future<void> _saveQuestionUpdate() async {
    final logId = _logId;
    if (logId == null) return;

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
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to selection for now
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
              Navigator.pop(context);
              _startNewQuestion(); // resume current question
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

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

              if (mounted) Navigator.pop(context);
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
    if (!_ready || _current == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final qIndex = _current!.index; // original 1..5
    final timeText = _formatTime(remainingSeconds);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---------- TOP BAR ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _confirmExit,
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),

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
                          'Question $qIndex / $totalQuestions',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '$a $_opSymbol $b = ?',
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
