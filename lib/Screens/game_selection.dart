import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'game_play_screen.dart';


class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {

  final List<String> gameNames = [
    'Addition',
    'Subtraction',
    'Multiplication',
    'Division',
  ];

  int? selectedLevel; // 1, 2, 3
  int? selectedGame;  // 1, 2, 3, 4

  bool get canPlay => selectedLevel != null && selectedGame != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top row: avatar, grey bar, home icon
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFDDDDDD),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      // Go back to home screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Level buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLevelButton(1, 'Level 1'),
                  _buildLevelButton(2, 'Level 2'),
                  _buildLevelButton(3, 'Level 3'),
                ],
              ),

              const SizedBox(height: 24),

              // Games grid 2x2
              _buildGamesRow(1, 2),
              const SizedBox(height: 24),
              _buildGamesRow(3, 4),

              const SizedBox(height: 32),

              // Play Game / Select button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: canPlay
                        ? () {
                      if (selectedGame == 1) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GamePlayScreen(
                              level: selectedLevel!,
                              game: selectedGame!,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('That game is not implemented yet.'),
                          ),
                        );
                      }
                    }

                    : null, // disabled until both chosen
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canPlay ? Colors.black : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Play Game',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Level button helper ----------

  Widget _buildLevelButton(int level, String label) {
    final bool isSelected = selectedLevel == level;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              selectedLevel = level;
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: const StadiumBorder(),
            side: BorderSide(
              color: isSelected ? Colors.black : Colors.grey.shade500,
              width: isSelected ? 2 : 1,
            ),
            backgroundColor:
            isSelected ? Colors.black : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // ---------- Games row helper (2 tiles) ----------

  Widget _buildGamesRow(int gameA, int gameB) {
    return Row(
      children: [
        _buildGameTile(gameA),
        const SizedBox(width: 16),
        _buildGameTile(gameB),
      ],
    );
  }


  Widget _buildGameTile(int gameNumber) {
    final bool isSelected = selectedGame == gameNumber;

    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                selectedGame = gameNumber;
              });
            },
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                  width: isSelected ? 3 : 1,
                ),
              ),
              // Later: replace this with Image.asset(...)
              child: const Center(
                child: Text('Image'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(gameNames[gameNumber - 1]),

        ],
      ),
    );
  }
}
