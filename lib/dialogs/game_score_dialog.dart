import 'package:flutter/material.dart';

Future<void> showTurnScoreDialog({
  required BuildContext context,
  required Future<void> finalizeFuture,
  required int earnedPoints,
  int? possiblePoints,
  String? scoreLabel,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return FutureBuilder<void>(
        future: finalizeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AlertDialog(
              title: Text("Calculating score"),
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(child: Text("Please wait...")),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: const Text("Score Update Failed"),
              content: const Text("Could not save this turn. Please try again."),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Next"),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text("Turn Complete"),
            content: Text(
              possiblePoints == null
                  ? "${scoreLabel ?? 'Score'}: $earnedPoints"
                  : "${scoreLabel ?? 'Score'}: $earnedPoints / $possiblePoints",
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Next"),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showEndedGameScoreDialog({
  required BuildContext context,
  required String winnerName,
  required String currentUsername,
  required int currentScore,
  required String opponentUsername,
  required int opponentScore,
}) async {
  final winnerLabel = winnerName == "Tie" ? "Winner: Tie Game" : "Winner: $winnerName";

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(winnerLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("$currentUsername: $currentScore"),
            const SizedBox(height: 8),
            Text("$opponentUsername: $opponentScore"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

Future<bool?> showActiveGameScoreDialog({
  required BuildContext context,
  required int currentRound,
  required String currentUsername,
  required int currentScore,
  required String opponentUsername,
  required int opponentScore,
  required bool canPlay,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Center(
          child: Text(
            "Round $currentRound",
            textAlign: TextAlign.center,
          )
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Current Score"),
            const SizedBox(height: 10),
            Text("$currentUsername: $currentScore"),
            const SizedBox(height: 8),
            Text("$opponentUsername: $opponentScore"),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Close"),
          ),
          if (canPlay)
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Play"),
            ),
        ],
      );
    },
  );
}
