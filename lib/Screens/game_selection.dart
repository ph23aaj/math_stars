import 'dart:math';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'game_play_screen.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  final List<String> gameNames = const [
    'Addition',
    'Subtraction',
    'Multiplication',
    'Division',
  ];

  int? selectedLevel; // 1,2,3
  int? selectedGame;  // 1..4

  bool get canPlay => selectedLevel != null && selectedGame != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.public, color: Colors.white),
                      ),
                      const Spacer(),
                      const Text(
                        'Choose your mission',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Level section
                  const Text(
                    'Pick a difficulty planet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(child: _LevelPlanet(level: 1, selectedLevel: selectedLevel, onTap: _setLevel)),
                      const SizedBox(width: 10),
                      Expanded(child: _LevelPlanet(level: 2, selectedLevel: selectedLevel, onTap: _setLevel)),
                      const SizedBox(width: 10),
                      Expanded(child: _LevelPlanet(level: 3, selectedLevel: selectedLevel, onTap: _setLevel)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Game section
                  const Text(
                    'Pick a maths world',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2x2 planets
                  Row(
                    children: [
                      Expanded(
                        child: _GamePlanetTile(
                          title: gameNames[0],
                          emoji: '➕',
                          gameNumber: 1,
                          selectedGame: selectedGame,
                          onTap: _setGame,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GamePlanetTile(
                          title: gameNames[1],
                          emoji: '➖',
                          gameNumber: 2,
                          selectedGame: selectedGame,
                          onTap: _setGame,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _GamePlanetTile(
                          title: gameNames[2],
                          emoji: '✖️',
                          gameNumber: 3,
                          selectedGame: selectedGame,
                          onTap: _setGame,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GamePlanetTile(
                          title: gameNames[3],
                          emoji: '➗',
                          gameNumber: 4,
                          selectedGame: selectedGame,
                          onTap: _setGame,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Launch button
                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: canPlay
                          ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GamePlayScreen(
                              level: selectedLevel!,
                              game: selectedGame!,
                            ),
                          ),
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canPlay ? const Color(0xFFFFD166) : Colors.white24,
                        foregroundColor: canPlay ? Colors.black : Colors.white70,
                        elevation: canPlay ? 14 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🚀', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 10),
                          Text(
                            'Launch Mission',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    canPlay ? 'Ready for take-off!' : 'Choose a planet + a world to start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
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

  void _setLevel(int level) => setState(() => selectedLevel = level);
  void _setGame(int game) => setState(() => selectedGame = game);
}

// ------------------ WIDGETS ------------------

class _LevelPlanet extends StatelessWidget {
  const _LevelPlanet({
    required this.level,
    required this.selectedLevel,
    required this.onTap,
  });

  final int level;
  final int? selectedLevel;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedLevel == level;

    final label = switch (level) {
      1 => 'Level 1',
      2 => 'Level 2',
      _ => 'Level 3',
    };

    // Make levels feel like planets: green -> amber -> red glow
    final Color planet = switch (level) {
      1 => const Color(0xFF4CAF50),
      2 => const Color(0xFFFFA500),
      _ => const Color(0xFFD1C4E9),
    };

    return GestureDetector(
      onTap: () => onTap(level),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD166) : Colors.white.withOpacity(0.18),
            width: isSelected ? 2.2 : 1.1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    planet.withOpacity(0.95),
                    planet.withOpacity(0.45),
                    planet.withOpacity(0.20),
                  ],
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFFFFD166).withOpacity(0.55),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamePlanetTile extends StatelessWidget {
  const _GamePlanetTile({
    required this.title,
    required this.emoji,
    required this.gameNumber,
    required this.selectedGame,
    required this.onTap,
  });

  final String title;
  final String emoji;
  final int gameNumber;
  final int? selectedGame;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedGame == gameNumber;

    return GestureDetector(
      onTap: () => onTap(gameNumber),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD166) : Colors.white.withOpacity(0.18),
            width: isSelected ? 2.2 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Planet
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSelected ? 'Selected ⭐' : 'Tap to select',
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
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

      paint.color = Colors.white.withOpacity(alpha);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }

    for (int i = 0; i < 16; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 2.0 + 1.2;

      paint.color = Colors.white.withOpacity(0.55);
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}