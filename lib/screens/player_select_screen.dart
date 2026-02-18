import 'package:flutter/material.dart';
import 'category_select_screen.dart';

class PlayerSelectScreen extends StatefulWidget {
  const PlayerSelectScreen({super.key});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen> {
  final List<TextEditingController> controllers = [];

  void addPlayer() {
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  void next() async {
    final players = controllers
        .map((c) => c.text.isEmpty ? "Random" : c.text)
        .toList();

    final game = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectScreen(players: players),
      ),
    );


    if (game != null) {
      Navigator.pop(context, game);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Players")),
      body: Column(
        children: [
          ElevatedButton(onPressed: addPlayer, child: const Text("+ Add Player")),
          Expanded(
            child: ListView.builder(
              itemCount: controllers.length,
              itemBuilder: (_, i) {
                return TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(labelText: "Player ${i + 1}"),
                );
              },
            ),
          ),
          ElevatedButton(onPressed: next, child: const Text("Next")),
        ],
      ),
    );
  }
}
