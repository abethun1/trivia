import 'package:flutter/material.dart';
import '../models/game.dart';

class CategorySelectScreen extends StatefulWidget {
  final List<String> players;

  const CategorySelectScreen({super.key, required this.players});

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  final List<String> allCategories = [
    "Science",
    "History",
    "Sports",
    "Movies",
    "Music",
    "Geography"
  ];

  final Set<String> selected = {};

  void toggle(String cat) {
    setState(() {
      if (selected.contains(cat)) {
        selected.remove(cat);
      } else if (selected.length < 5) {
        selected.add(cat);
      }
    });
  }

  void showConfirmationDialog() {
    if (selected.isEmpty) return;

    final screenContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Create Game?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Players:"),
            Text(widget.players.join(", ")),
            const SizedBox(height: 8),
            const Text("Categories:"),
            Text(selected.join(", ")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Go Back"),
          ),
          ElevatedButton(
            onPressed: () {
              final game = Game(
                players: widget.players,
                categories: selected.toList(),
                createdAt: DateTime.now(),
              );

              Navigator.pop(dialogContext); // close dialog first

              Future.microtask(() {
                Navigator.pop(screenContext, game); // then pop screen
              });
            },
            child: const Text("Create Game"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Categories")),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Choose up to 5 categories"),
          ),
          Wrap(
            spacing: 8,
            children: allCategories.map((cat) {
              final isSelected = selected.contains(cat);
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (_) => toggle(cat),
              );
            }).toList(),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: showConfirmationDialog,
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}
