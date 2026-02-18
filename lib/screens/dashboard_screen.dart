import 'package:flutter/material.dart';

//Styles
import '../styles/dashboard_styles.dart';

//Screens
import 'player_select_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void startNewGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlayerSelectScreen()),
    );
  }

  Widget buildGameSection(String title, List<String> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DashboardStyles.sectionTitle),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: games.map((game) {
              return Padding(
                padding: DashboardStyles.gameCirclePadding,
                child: Container(
                  width: DashboardStyles.gameCircleSize,
                  height: DashboardStyles.gameCircleSize,
                  decoration: DashboardStyles.gameCircleDecoration,
                  alignment: Alignment.center,
                  child: Text(game, style: DashboardStyles.gameCircleText),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("{User Name} Dashboard")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              // TOP ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: DashboardStyles.statsCardDecoration,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rank: Gold", style: DashboardStyles.statsText),
                          Text("Top Category: Math", style: DashboardStyles.statsText),
                          Text("Correct Answers: 100", style: DashboardStyles.statsText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector
                  (
                    onTap: ()
                    {
                      Navigator.push
                      (
                        context,
                        MaterialPageRoute
                        (
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: const CircleAvatar
                    (
                      radius: 40,
                      backgroundColor: Color.fromARGB(255, 197, 38, 38),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // START GAME BUTTON
              SizedBox(
                width: size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () => startNewGame(context),
                  style: DashboardStyles.startGameButtonStyle,
                  child: const Text("Start New Game", style: TextStyle(fontSize: 20)),
                ),
              ),

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerLeft,
                child: buildGameSection("Your Turn", ["G4", "G5", "G7", "G7"]),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: buildGameSection("Their Turn", ["G3"]),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: buildGameSection("Request", ["G4", "G5"]),
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: buildGameSection("Ended Games", ["G1", "G2"]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
