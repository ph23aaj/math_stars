import 'package:flutter/material.dart';
import 'package:math_stars/Widgets/ui_cards.dart';
import 'game_play_screen.dart';
import 'mock_game_screen.dart';

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

  int? selectedLevel; // 1, 2, 3, or 5 = Mock
  int? selectedGame;  // 1..4

  // Mock mode is active when the player selects the Mock tile
  bool get _isMockMode => selectedLevel == 5;

  // In Mock mode, only a game selected is needed (no level);
  // in standard mode both is required.
  bool get canPlay =>
      selectedGame != null &&
          (_isMockMode || selectedLevel != null && selectedLevel! <= 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SpaceBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ----- Top row ---------
                  Row(
                    children: [
                      GlassIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Choose your mission',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GlassIconButton(
                        icon: Icons.settings_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ------ Level section ----------
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
                      Expanded(
                        child: _LevelPlanet(
                          level: 1,
                          selectedLevel: selectedLevel,
                          onTap: _setLevel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LevelPlanet(
                          level: 2,
                          selectedLevel: selectedLevel,
                          onTap: _setLevel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LevelPlanet(
                          level: 3,
                          selectedLevel: selectedLevel,
                          onTap: _setLevel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ------- Mock planet -----------
                      Expanded(
                        child: _MockPlanet(
                          selectedLevel: selectedLevel,
                          onTap: _setLevel,
                        ),
                      ),
                    ],
                  ),

                  // Mock description (shown only when Mock is selected)
                  if (_isMockMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        'Mock mode: 3 rounds of 5 questions. '
                            'Your difficulty adapts automatically based on your score.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // -------- Game section ---------------
                  const Text(
                    'Pick a maths world',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),

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

                  // ------- Launch button ------------
                  SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: canPlay ? _launch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        canPlay ? const Color(0xFFFFD166) : Colors.white24,
                        foregroundColor:
                        canPlay ? Colors.black : Colors.white70,
                        elevation: canPlay ? 14 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🚀', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(
                            _isMockMode ? 'Launch Mock' : 'Launch Mission',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    canPlay
                        ? 'Ready for take-off!'
                        : 'Choose a planet + a world to start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
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
  void _setGame(int game)   => setState(() => selectedGame  = game);

  void _launch() {
    if (!canPlay) return;
    if (_isMockMode) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MockGameScreen(game: selectedGame!),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GamePlayScreen(
            level: selectedLevel!,
            game:  selectedGame!,
          ),
        ),
      );
    }
  }
}

// ------ Mock planet tile ------------

class _MockPlanet extends StatelessWidget {
  const _MockPlanet({
    required this.selectedLevel,
    required this.onTap,
  });

  final int? selectedLevel;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedLevel == 5;

    return GestureDetector(
      onTap: () => onTap(5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSelected ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD166)
                : Colors.white.withValues(alpha: 0.18),
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
                    const Color(0xFFAF52DE).withValues(alpha: 0.95),
                    const Color(0xFFAF52DE).withValues(alpha: 0.45),
                    const Color(0xFFAF52DE).withValues(alpha: 0.20),
                  ],
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mock',
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

// ------ Standard level planet -------

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
          color: Colors.white.withValues(alpha: isSelected ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD166)
                : Colors.white.withValues(alpha: 0.18),
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
                    planet.withValues(alpha: 0.95),
                    planet.withValues(alpha: 0.45),
                    planet.withValues(alpha: 0.20),
                  ],
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
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

// --------- Game planet tile ---------------

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
        height: 158,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSelected ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD166)
                : Colors.white.withValues(alpha: 0.18),
            width: isSelected ? 2.2 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSelected ? 'Selected ⭐' : 'Tap to select',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}