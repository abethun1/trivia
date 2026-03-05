import 'package:flutter/material.dart';

import '../screens/category_select_screen.dart';

enum InviteAction
{
  pickCategories,
  rejectGame,
}

class InviteDialogResult
{
  final InviteAction action;
  final List<String>? categories;

  const InviteDialogResult._(this.action, this.categories);

  const InviteDialogResult.pickCategories(List<String> categories)
      : this._(InviteAction.pickCategories, categories);

  const InviteDialogResult.rejectGame()
      : this._(InviteAction.rejectGame, null);
}

Future<InviteDialogResult?> showInviteDialog
({
  required BuildContext context,
  required String hostUsername,
  required String gameId,
})
{
  return showDialog<InviteDialogResult>
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
              final shouldReject = await showDialog<bool>
              (
                context: dialogContext,
                builder: (confirmContext)
                {
                  return AlertDialog
                  (
                    title: const Text("Reject Game?"),
                    content: const Text(
                      "Are you sure? This will permanently delete this game request.",
                    ),
                    actions:
                    [
                      TextButton
                      (
                        onPressed: ()
                        {
                          Navigator.pop(confirmContext, false);
                        },
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton
                      (
                        onPressed: ()
                        {
                          Navigator.pop(confirmContext, true);
                        },
                        child: const Text("Yes, Reject"),
                      ),
                    ],
                  );
                },
              );

              if (shouldReject == true)
              {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, const InviteDialogResult.rejectGame());
              }
            },
            child: const Text("Reject Game"),
          ),
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
              if (result != null)
              {
                if (!dialogContext.mounted) return;
                Navigator.pop(
                  dialogContext,
                  InviteDialogResult.pickCategories(result),
                );
              }
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
