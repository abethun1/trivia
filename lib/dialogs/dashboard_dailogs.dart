import 'package:flutter/material.dart';

import '../screens/category_select_screen.dart';
import '../models/game.dart';

Future<List<String>?> showInviteDialog
({
  required BuildContext context,
  required String hostUsername,
  required String gameId,
})
{
  return showDialog<List<String>>
  (
    context: context,
    builder: (dialogContext)
    {
      return AlertDialog
      (
        title: const Text("Game Invitation"),
        content: Text("$hostUsername has invited you to play"),
        actionsAlignment: MainAxisAlignment.center,
        actions:
        [
          ElevatedButton
          (
            onPressed: () async
            {
              final result = await Navigator.push<List<String>>
              (
                context,
                MaterialPageRoute
                (
                  builder: (_) => CategorySelectScreen
                  (
                    gameId: gameId,
                    isJoining: true,
                  ),
                ),
              );
              Navigator.pop(dialogContext, result);
            },
            child: const Text("Pick Categories"),
          ),
        ],
      );
    },
  );
}
void showGameCreatingDialog(BuildContext context) {
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Your game is being created...",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  },
);
}