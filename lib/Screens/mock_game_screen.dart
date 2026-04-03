import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Services/game_log_service.dart';
import '../Services/progress_service.dart';
import 'package:math_stars/Widgets/ui_cards.dart';

// ------ Mock mode constants ---------------
const int    _kBlockSize        = 5;    // questions per evaluation block
const int    _kTotalBlocks      = 3;    // 3 blocks = 15 questions total
const double _kPromoteThreshold = 0.70; // ≥70% correct then promote level
const double _kDemoteThreshold  = 0.40; // <40% correct then demote level

class MockGameScreen extends StatefulWidget {
  final int game;  // 1 = addition, 2 = subtraction, 3 = multiplication, 4 = division

  const MockGameScreen({
    super.key,
    required this.game,
  });

  @override
  State<MockGameScreen> createState() => _MockGameScreenState();
}

class _Q {
  final String id;
  final int index;
  final int a;
  final int b;

  const _Q({
    required this.id,
    required this.index,
    required this.a,
    required this.b,
  });
}

class _MockGameScreenState extends State<MockGameScreen> with TickerProviderStateMixin {

  static const int totalQuestions = _kBlockSize * _kTotalBlocks; // 15

  // Game mapping: 1=addition, 2=subtraction, 3=multiplication, 4=division
  bool get _isAddition       => widget.game == 1;
  bool get _isSubtraction    => widget.game == 2;
  bool get _isMultiplication => widget.game == 3;
  bool get _isDivision       => widget.game == 4;

  String get _gameId {
    if (_isSubtraction)    return 'subtraction';
    if (_isMultiplication) return 'multiplication';
    if (_isDivision)       return 'division';
    return 'addition';
  }

  String get _gameName {
    if (_isSubtraction)    return 'Subtraction';
    if (_isMultiplication) return 'Multiplication';
    if (_isDivision)       return 'Division';
    return 'Addition';
  }

  String get _opSymbol {
    if (_isSubtraction)    return '-';
    if (_isMultiplication) return '×';
    if (_isDivision)       return '÷';
    return '+';
  }

  int _computeAnswer(int a, int b) {
    if (_isSubtraction)    return a - b;
    if (_isMultiplication) return a * b;
    if (_isDivision)       return a ~/ b;
    return a + b;
  }

  late final AnimationController _sparkleCtrl;
  late final AnimationController _shakeCtrl;

  final Random _sparkleRnd = Random(42);

  // ------- Adaptive level state -------------------
  int _currentLevel = 1;  // current difficulty level (1, 2, or 3)
  int _blockIndex   = 0;  // which block user is on (0-based)
  int _blockCorrect = 0;  // correct answers in the current block
  int _blockTotal   = 0;  // questions answered in the current block

  // -------- Difficulty helpers ---------------
  List<int> _tablesForLevel(int level) {
    switch (level) {
      case 1:  return [2, 5, 10];
      case 2:  return [3, 4, 8];
      case 3:  return [6, 7, 9, 11, 12];
      default: return [2, 5, 10];
    }
  }

  _Q _makeQuestion(int index) {
    final level = _currentLevel;

    // Addition
    if (_isAddition) {
      if (level == 1) {
        final qa = rng.nextInt(11);
        final qb = rng.nextInt(11 - qa);
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else if (level == 2) {
        int qa = rng.nextInt(21);
        int qb = rng.nextInt(21 - qa);
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else {
        final qa = rng.nextInt(90) + 10;
        final qb = rng.nextInt(90) + 10;
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      }
    }

    // Subtraction
    if (_isSubtraction) {
      if (level == 1) {
        int qa = rng.nextInt(11);
        int qb = rng.nextInt(qa + 1);
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else if (level == 2) {
        int qa = rng.nextInt(21);
        int qb = rng.nextInt(qa + 1);
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      } else {
        int qa = rng.nextInt(90) + 10;
        int qb = rng.nextInt(qa - 9) + 10;
        return _Q(id: 'q$index', index: index, a: qa, b: qb);
      }
    }

    // Multiplication
    if (_isMultiplication) {
      final tables = _tablesForLevel(level);
      final qa = tables[rng.nextInt(tables.length)];
      final qb = rng.nextInt(12) + 1;
      return _Q(id: 'q$index', index: index, a: qa, b: qb);
    }

    // Division (exact)
    if (_isDivision) {
      final tables     = _tablesForLevel(level);
      final divisor    = tables[rng.nextInt(tables.length)];
      final multiplier = rng.nextInt(12) + 1;
      final dividend   = divisor * multiplier;
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

  int a = 1;
  int b = 1;
  int get correctAnswer => _computeAnswer(a, b);

  int score     = 0;
  int incorrect = 0;

  final List<_Q> _queue   = [];
  _Q? _current;

  DateTime?_questionStart;
  String?_logId;
  bool _saving = false;
  final List<Map<String, dynamic>> _questionLogs = [];
  final Map<String, int> _attemptCountByQuestionId = {};

  @override
  void initState() {
    super.initState();
    _sparkleCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 520),
    );
    _shakeCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 360),
    );
    _initLogAndStart();
  }

  Future<void> _initLogAndStart() async {
    setState(() => _ready = false);

    // Reset adaptive state
    _currentLevel = 1;
    _blockIndex   = 0;
    _blockCorrect = 0;
    _blockTotal   = 0;

    try {
      _logId = await GameLogService().createLog(
        gameId: 'mock_$_gameId',
        gameName: 'Mock - $_gameName',
        level: _currentLevel,
        totalQuestions: totalQuestions,
      );
    } catch (e) {
      debugPrint('Failed to create mock log: $e');
      _logId = null;
    }

    answer = '';
    score  = 0;
    incorrect = 0;

    _queue.clear();
    _current = null;
    _questionLogs.clear();
    _attemptCountByQuestionId.clear();

    // Build the first block
    _buildNextBlock(startIndex: 1);

    _current = _queue.removeAt(0);

    setState(() => _ready = true);
    _startNewQuestion();
  }

  // Build _kBlockSize questions at the current level and add them to the queue
  void _buildNextBlock({required int startIndex}) {
    for (int i = 0; i < _kBlockSize; i++) {
      _queue.add(_makeQuestion(startIndex + i));
    }
  }

  // Evaluate accuracy after a completed block and adjust level
  void _evaluateBlockAndAdvance() {
    final accuracy = _blockTotal == 0 ? 0.0 : _blockCorrect / _blockTotal;

    if (accuracy >= _kPromoteThreshold && _currentLevel < 3) {
      _currentLevel++;
    } else if (accuracy < _kDemoteThreshold && _currentLevel > 1) {
      _currentLevel--;
    }
    // else: stay at current level

    _blockCorrect = 0;
    _blockTotal   = 0;
    _blockIndex++;
  }

  void _startNewQuestion() {
    final q = _current;
    if (q == null) return;

    a = q.a;
    b = q.b;

    answer         = '';
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
    final int? parsed    = int.tryParse(answer);
    final bool isCorrect = (parsed != null && parsed == correctAnswer);

    if (isCorrect) {
      _playSparkles();
    } else {
      _playShake();
    }

    _submitAttempt(
      isCorrect:  isCorrect,
      userAnswer: parsed,
      timedOut:   false,
      snack:      isCorrect ? 'Correct! +1' : 'Incorrect',
    );
  }

  Future<void> _submitAttempt({
    required bool   isCorrect,
    required int?   userAnswer,
    required bool   timedOut,
    required String snack,
  }) async {
    final q = _current;
    if (q == null) return;

    final attemptNo = (_attemptCountByQuestionId[q.id] ?? 0) + 1;
    _attemptCountByQuestionId[q.id] = attemptNo;

    final now         = DateTime.now();
    final timeTakenMs = _questionStart == null
        ? 0
        : now.difference(_questionStart!).inMilliseconds;

    if (isCorrect) {
      score++;
      _blockCorrect++;
    } else {
      incorrect++;
    }
    _blockTotal++;

    _questionLogs.add({
      'questionId':    q.id,
      'questionIndex': q.index,
      'a':             q.a,
      'b':             q.b,
      'operator':      _opSymbol,
      'correctAnswer': _computeAnswer(q.a, q.b),
      'userAnswer':    userAnswer,
      'isCorrect':     isCorrect,
      'timeTakenMs':   timeTakenMs,
      'timedOut':      timedOut,
      'level':         _currentLevel,
    });

    await _saveQuestionUpdate();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  Text(snack),
          duration: const Duration(milliseconds: 700),
        ),
      );
    }

    //----- Check if this block is complete ---------
    if (_blockTotal == _kBlockSize) {
      final completedBlocks = _blockIndex + 1;

      // All blocks done, then finish session
      if (completedBlocks >= _kTotalBlocks) {
        await _finishGame();
        return;
      }

      // Evaluate and build next block
      _evaluateBlockAndAdvance();
      final nextStart = _questionLogs.length + 1;
      _buildNextBlock(startIndex: nextStart);
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
    if (logId == null || _saving) return;
    _saving = true;

    try {
      await GameLogService().updateAfterQuestion(
        logId:             logId,
        questionIndex:     _questionLogs.length + 1,
        correct:           score,
        incorrect:         incorrect,
        questionLog:       _questionLogs.isEmpty ? {} : _questionLogs.last,
        allQuestionsSoFar: List<Map<String, dynamic>>.from(_questionLogs),
      );
    } catch (e) {
      debugPrint('Failed to update mock log: $e');
    } finally {
      _saving = false;
    }
  }

  Future<void> _finishGame() async {
    int computeAvgTimeMs() {
      if (_questionLogs.isEmpty) return 0;
      final total = _questionLogs.fold<int>(
        0, (sum, q) => sum + ((q['timeTakenMs'] ?? 0) as int),
      );
      return (total / _questionLogs.length).round();
    }

    final logId = _logId;
    if (logId != null) {
      final avg = computeAvgTimeMs();
      try {
        await GameLogService().markCompleted(
          logId:     logId,
          correct:   score,
          incorrect: incorrect,
          avgTimeMs: avg,
        );
      } catch (e) {
        debugPrint('Failed to mark mock completed: $e');
      }
    }

    try {
      await ProgressService().recordGameResultSimple(
        gameId:    'mock_$_gameId',
        correct:   score,
        incorrect: incorrect,
        level:     _currentLevel,
      );
    } catch (e) {
      debugPrint('Failed to update progress: $e');
    }

    if (!mounted) return;

    final pct = (score / totalQuestions * 100).round();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title:   const Text('Mock complete'),
        content: Column(
          mainAxisSize:MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: $score / $totalQuestions ($pct%)'),
            const SizedBox(height: 8),
            Text('Final level reached: $_currentLevel'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title:   const Text('Exit mock?'),
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
                    logId:     logId,
                    correct:   score,
                    incorrect: incorrect,
                  );
                } catch (e) {
                  debugPrint('Failed to mark mock abandoned: $e');
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

  void _playSparkles() => _sparkleCtrl.forward(from: 0);
  void _playShake()    => _shakeCtrl.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    if (!_ready || _current == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final qIndex    = _current!.index;
    final blockNum  = _blockIndex + 1;

    return Scaffold(
      body: Stack(
        children: [
          const SpaceBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [

                  // ---------- TOP BAR ----------
                  Row(
                    children: [
                      GlassIconButton(
                        icon:  Icons.close,
                        onTap: _confirmExit,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Mock - $_gameName • Level $_currentLevel',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize:   16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 12),

                      _ScorePill(score: score),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ---------- BLOCK PROGRESS ----------
                  _BlockProgress(
                    blockNum:    blockNum,
                    totalBlocks: _kTotalBlocks,
                    blockTotal:  _blockTotal,
                    blockSize:   _kBlockSize,
                  ),

                  const SizedBox(height: 10),

                  // ---------- GAME AREA ----------
                  GlassCard(
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
                            IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _sparkleCtrl,
                                builder: (_, _) {
                                  return CustomPaint(
                                    size:    const Size(280, 110),
                                    painter: _SparkleBurstPainter(
                                      t:    _sparkleCtrl.value,
                                      seed: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Text(
                              '$a $_opSymbol $b = ?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   44,
                                fontWeight: FontWeight.w900,
                                height:     1.0,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        AnimatedBuilder(
                          animation: _shakeCtrl,
                          builder: (context, child) {
                            final t   = _shakeCtrl.value;
                            final amp = (1.0 - t) * 10.0;
                            final dx  = sin(t * pi * 10) * amp;
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child:  child,
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
                      onDigit:     _pressDigit,
                      onBackspace: _backspace,
                      onEnter:     _enter,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Type your answer and launch Enter',
                    style: TextStyle(
                      color:      Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      fontSize:   12,
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

// ------------------ BLOCK PROGRESS INDICATOR ------------------

class _BlockProgress extends StatelessWidget {
  const _BlockProgress({
    required this.blockNum,
    required this.totalBlocks,
    required this.blockTotal,
    required this.blockSize,
  });

  final int blockNum;
  final int totalBlocks;
  final int blockTotal;
  final int blockSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalBlocks, (i) {
        final isActive   = i + 1 == blockNum;
        final isComplete = i + 1 <  blockNum;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Text(
                  'Block ${i + 1}',
                  style: TextStyle(
                    color:      Colors.white.withValues(alpha: isActive ? 0.95 : 0.45),
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: isComplete
                        ? 1.0
                        : isActive
                        ? blockTotal / blockSize
                        : 0.0,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFFD166),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ------------------ SCORE PILL ------------------

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
              color:      Colors.white,
              fontWeight: FontWeight.w900,
              fontSize:   15,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ MINI CHIP ------------------

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
          color:      Colors.white.withValues(alpha: 0.90),
          fontWeight: FontWeight.w800,
          fontSize:   12,
        ),
      ),
    );
  }
}

// ------------------ ANSWER BOX ------------------

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
          color:       Colors.white,
          fontSize:    30,
          fontWeight:  FontWeight.w900,
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
            _key('Delete', onTap: onBackspace, isAction: true),
            _key('Enter', onTap: onEnter, isPrimary: true),
          ],
        ),
      ],
    );
  }

  Widget _key(
      String label, {
        required VoidCallback onTap,
        bool isPrimary = false,
        bool isAction  = false,
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
                    color:      Colors.black.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset:     const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color:      Colors.white.withValues(alpha: isPrimary ? 0.95 : 0.92),
                  fontSize:   18,
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

// ------------------ SPARKLE BURST PAINTER ------------------

class _SparkleBurstPainter extends CustomPainter {
  _SparkleBurstPainter({
    required this.t,
    required this.seed,
  });

  final double t;
  final int    seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    final progress = Curves.easeOutCubic.transform(t);
    final fade     = (1.0 - t).clamp(0.0, 1.0);

    final rnd   = Random(seed);
    final cx    = size.width  / 2;
    final cy    = size.height / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 26; i++) {
      final angle  = rnd.nextDouble() * pi * 2;
      final dist   = (rnd.nextDouble() * 42 + 12) * progress;
      final x      = cx + cos(angle) * dist;
      final y      = cy + sin(angle) * dist;
      final r      = (rnd.nextDouble() * 2.4 + 1.0) * (1.0 - t * 0.6);
      final isWarm = rnd.nextBool();

      paint.color = (isWarm ? const Color(0xFFFFD166) : const Color(0xFF9FD3FF))
          .withValues(alpha: 0.75 * fade);

      canvas.drawCircle(Offset(x, y), r, paint);
    }

    final glow = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color       = const Color(0xFFFFD166).withValues(alpha: 0.22 * fade);

    canvas.drawCircle(Offset(cx, cy), 18 + 34 * progress, glow);
  }

  @override
  bool shouldRepaint(covariant _SparkleBurstPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.seed != seed;
  }
}