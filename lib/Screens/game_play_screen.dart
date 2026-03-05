import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Services/game_log_service.dart';

class GamePlayScreen extends StatefulWidget {
  final int level; // 1, 2, 3
  final int game;  // 1 = addition, 2 = subtraction, 3=multiplication, 4=division

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

class _GamePlayScreenState extends State<GamePlayScreen> with TickerProviderStateMixin {
  static const int totalQuestions = 5;

  // Game mapping: 1=addition, 2=subtraction, 3=multiplication, 4=division
  bool get _isAddition => widget.game == 1;
  bool get _isSubtraction => widget.game == 2;
  bool get _isMultiplication => widget.game == 3;
  bool get _isDivision => widget.game == 4;

  String get _gameId {
    if (_isSubtraction) return 'subtraction';
    if (_isMultiplication) return 'multiplication';
    if (_isDivision) return 'division';
    return 'addition';
  }

  String get _gameName {
    if (_isSubtraction) return 'Subtraction';
    if (_isMultiplication) return 'Multiplication';
    if (_isDivision) return 'Division';
    return 'Addition';
  }

  String get _opSymbol {
    if (_isSubtraction) return '-';
    if (_isMultiplication) return '×';
    if (_isDivision) return '÷';
    return '+';
  }

  int _computeAnswer(int a, int b) {
    if (_isSubtraction) return a - b;
    if (_isMultiplication) return a * b;
    if (_isDivision) return a ~/ b;
    return a + b;
  }

  late final AnimationController _sparkleCtrl;
  late final AnimationController _shakeCtrl;

  final Random _sparkleRnd = Random(42);

  // ---------------- Difficulty helpers ----------------

  // For multiplication/division progression
  List<int> _tablesForLevel(int level) {
    switch (level) {
      case 1:
        return [2, 5, 10];
      case 2:
        return [3, 4, 8];
      case 3:
        return [6, 7, 9, 11, 12];
      default:
        return [2, 5, 10];
    }
  }

  // Create 1 base question (index is 1..5)
  _Q _makeQuestion(int index) {
    // Addition
    if (_isAddition) {
      if (widget.level == 1) {
        final qa = rng.nextInt(11); // 0..10
        final qb = rng.nextInt(11 - qa); // keeps sum <= 10
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else if (widget.level == 2) {
        int qa = rng.nextInt(21); // 0..20
        int qb = rng.nextInt(21 - qa);
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else {
        final qa = rng.nextInt(90) + 10; // 10..99
        final qb = rng.nextInt(90) + 10; // 10..99
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      }
    }

    // Subtraction
    if (_isSubtraction) {
      if (widget.level == 1) {
        int qa = rng.nextInt(11); // 0..10
        int qb = rng.nextInt(qa + 1); // 0..qa
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else if (widget.level == 2) {
        int qa = rng.nextInt(21); // 0..20
        int qb = rng.nextInt(qa + 1);
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else {
        int qa = rng.nextInt(90) + 10; // 10..99
        int qb = rng.nextInt(qa - 9) + 10; // 10..qa
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      }
    }

    // Multiplication
    if (_isMultiplication) {
      final tables = _tablesForLevel(widget.level);
      final qa = tables[rng.nextInt(tables.length)];
      final qb = rng.nextInt(12) + 1;
      return _Q(id: 'q$index', index: index, a: qa, b: qb);
    }

    // Division (exact)
    if (_isDivision) {
      final tables = _tablesForLevel(widget.level);
      final divisor = tables[rng.nextInt(tables.length)];
      final multiplier = rng.nextInt(12) + 1;
      final dividend = divisor * multiplier;
      return _Q(id: 'q$index', index: index, a: dividend, b: divisor);
    }

    // Fallback
    final qa = rng.nextInt(12) + 1;
    final qb = rng.nextInt(12) + 1;
    return _Q(id: 'q$index', index: index, a: qa, b: qb);
  }

  final Random rng = Random();

  bool _ready = false;

  String answer = '';

  // Current displayed values
  int a = 1;
  int b = 1;
  int get correctAnswer => _computeAnswer(a, b);

  // Counters
  int score = 0;
  int incorrect = 0;

  // Queue (no repeats)
  final List<_Q> _queue = [];
  _Q? _current;

  // Logging
  DateTime? _questionStart;
  String? _logId;
  bool _saving = false;
  final List<Map<String, dynamic>> _questionLogs = [];
  final Map<String, int> _attemptCountByQuestionId = {}; // kept but unused now (fine)

  @override
  void initState() {
    super.initState();
    _initLogAndStart();
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _initLogAndStart();
  }

  Future<void> _initLogAndStart() async {
    setState(() => _ready = false);

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

    answer = '';
    score = 0;
    incorrect = 0;

    _queue.clear();
    _current = null;

    _questionLogs.clear();
    _attemptCountByQuestionId.clear();

    for (int i = 1; i <= totalQuestions; i++) {
      _queue.add(_makeQuestion(i));
    }

    _current = _queue.removeAt(0);

    setState(() => _ready = true);
    _startNewQuestion();
  }

  void _startNewQuestion() {
    final q = _current;
    if (q == null) return;

    a = q.a;
    b = q.b;

    answer = '';
    _questionStart = DateTime.now();

    setState(() {});
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

    if (isCorrect) {
      _playSparkles();
    } else {
      _playShake();
    }

    _submitAttempt(
      isCorrect: isCorrect,
      userAnswer: parsed,
      timedOut: false,
      snack: isCorrect ? 'Correct! +1' : 'Incorrect',
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

    final attemptNo = (_attemptCountByQuestionId[q.id] ?? 0) + 1;
    _attemptCountByQuestionId[q.id] = attemptNo;

    final now = DateTime.now();
    final timeTakenMs =
    _questionStart == null ? 0 : now.difference(_questionStart!).inMilliseconds;

    if (isCorrect) {
      score += 1;
    } else {
      incorrect += 1;
    }

    _questionLogs.add({
      'questionId': q.id,
      'questionIndex': q.index,
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
        questionIndex: _questionLogs.length + 1,
        correct: score,
        incorrect: incorrect,
        questionLog: _questionLogs.isEmpty ? {} : _questionLogs.last,
        allQuestionsSoFar: List<Map<String, dynamic>>.from(_questionLogs),
      );
    } catch (e) {
      debugPrint('Failed to update game log: $e');
    } finally {
      _saving = false;
    }
  }

  Future<void> _finishGame() async {
    int computeAvgTimeMs() {
      if (_questionLogs.isEmpty) return 0;
      final total = _questionLogs.fold<int>(
        0,
            (sum, q) => sum + ((q['timeTakenMs'] ?? 0) as int),
      );
      return (total / _questionLogs.length).round();
    }

    final logId = _logId;
    if (logId != null) {
      final avg = computeAvgTimeMs();
      try {
        await GameLogService().markCompleted(
          logId: logId,
          correct: score,
          incorrect: incorrect,
          avgTimeMs: avg,
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
        title: const Text('Mission complete 🚀'),
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
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit mission?'),
        content: const Text('Your current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewQuestion();
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

  @override
  void dispose() {
    _sparkleCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _playSparkles() {
    _sparkleCtrl.forward(from: 0);
  }

  void _playShake() {
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _current == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final qIndex = _current!.index;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (space)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1026),
                  Color(0xFF1A2A6C),
                  Color(0xFF2B1055),
                ],
              ),
            ),
          ),

          // Stars overlay
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _StarFieldPainter()),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // ---------- TOP BAR ----------
                  Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.close,
                        onTap: _confirmExit,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          '$_gameName • Level ${widget.level}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 12),

                      _ScorePill(score: score),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ---------- GAME AREA ----------
                  _GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _MiniChip(text: 'Question $qIndex / $totalQuestions'),
                            const Spacer(),
                            _MiniChip(text: 'Wrong: $incorrect'),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sparkles behind
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _sparkleCtrl,
                                builder: (_, __) {
                                  return CustomPaint(
                                    size: const Size(280, 110),
                                    painter: _SparkleBurstPainter(
                                      t: _sparkleCtrl.value,
                                      seed: 11,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // The question text on top
                            Text(
                              '$a $_opSymbol $b = ?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        AnimatedBuilder(
                          animation: _shakeCtrl,
                          builder: (context, child) {
                            // Decaying shake: 0 -> 1
                            final t = _shakeCtrl.value;
                            final amp = (1.0 - t) * 10.0; // max pixels
                            final dx = sin(t * pi * 10) * amp; // oscillation
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: _AnswerBox(text: answer),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ---------- KEYPAD ----------
                  Expanded(
                    child: _Keypad(
                      onDigit: _pressDigit,
                      onBackspace: _backspace,
                      onEnter: _enter,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Type your answer and launch ↵',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
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

// ------------------ SPACE UI WIDGETS ------------------

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD166).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.90),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AnswerBox extends StatelessWidget {
  const _AnswerBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final shown = text.isEmpty ? ' ' : text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        shown,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

// ------------------ KEYPAD (SPACE THEME) ------------------

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
        const SizedBox(height: 12),
        Row(
          children: [
            _key('7', onTap: () => onDigit(7)),
            _key('8', onTap: () => onDigit(8)),
            _key('9', onTap: () => onDigit(9)),
            _key('0', onTap: () => onDigit(0)),
            _key('⌫', onTap: onBackspace, isAction: true),
            _key('↵', onTap: onEnter, isPrimary: true),
          ],
        ),
      ],
    );
  }

  Widget _key(
      String label, {
        required VoidCallback onTap,
        bool isPrimary = false,
        bool isAction = false,
      }) {
    final Color border = isPrimary
        ? const Color(0xFFFFD166)
        : Colors.white.withValues(alpha: 0.18);

    final Color bg = isPrimary
        ? const Color(0xFFFFD166).withValues(alpha: 0.22)
        : isAction
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.10);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          height: 52,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border.withValues(alpha: isPrimary ? 0.55 : 1.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isPrimary ? 0.95 : 0.92),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ STARS ------------------

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(11);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 190; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;

      final r = rnd.nextDouble() * 1.4 + 0.4;
      final alpha = (rnd.nextDouble() * 0.55 + 0.12);

      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }

    for (int i = 0; i < 16; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 2.0 + 1.2;

      paint.color = Colors.white.withValues(alpha: 0.55);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SparkleBurstPainter extends CustomPainter {
  _SparkleBurstPainter({
    required this.t,
    required this.seed,
  });

  final double t; // 0..1
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    // Burst expands then fades
    final progress = Curves.easeOutCubic.transform(t);
    final fade = (1.0 - t).clamp(0.0, 1.0);

    final rnd = Random(seed);
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Two colours: warm + cool sparkles
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 26; i++) {
      final angle = rnd.nextDouble() * pi * 2;
      final dist = (rnd.nextDouble() * 42 + 12) * progress; // expand
      final x = cx + cos(angle) * dist;
      final y = cy + sin(angle) * dist;

      final r = (rnd.nextDouble() * 2.4 + 1.0) * (1.0 - t * 0.6);
      final isWarm = rnd.nextBool();

      paint.color = (isWarm ? const Color(0xFFFFD166) : const Color(0xFF9FD3FF))
          .withValues(alpha: 0.75 * fade);

      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // A soft glow ring
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFFFFD166).withValues(alpha: 0.22 * fade);

    canvas.drawCircle(Offset(cx, cy), 18 + 34 * progress, glow);
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.seed != seed;
  }
}