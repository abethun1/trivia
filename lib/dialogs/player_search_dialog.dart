import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../widgets/fancy_search_bar.dart';

class PlayerSearchDialog extends StatefulWidget
{
  final List<UserProfile> selectedPlayers;

  const PlayerSearchDialog
  (
    {
      super.key,
      required this.selectedPlayers,
    }
  );

  @override
  State<PlayerSearchDialog> createState()
  {
    return _PlayerSearchDialogState();
  }
}

class _PlayerSearchDialogState extends State<PlayerSearchDialog>
{
  final supabase = Supabase.instance.client;

  final TextEditingController controller = TextEditingController();

  List<UserProfile> results = [];
  UserProfile? selectedUser;
  bool loading = false;

  Future<void> searchUsers(String query) async
  {
    if (query.isEmpty)
    {
      setState
      (
        ()
        {
          results = [];
        },
      );
      return;
    }

    setState
    (
      ()
      {
        loading = true;
      },
    );

    final data = await supabase
        .from('user_profiles')
        .select('id, username')
        .ilike('username', '%$query%')
        .neq('username', '')
        .not('username', 'is', null)
        .limit(5);

    setState
    (
      ()
      {
        results = data
            .map<UserProfile>
            (
              (row) => UserProfile.fromMap(row),
            )
            .toList();
        loading = false;
      },
    );
  }

  Future<void> pickRandomUser() async
  {
    setState
    (
      ()
      {
        loading = true;
      },
    );

    final currentUserId = supabase.auth.currentUser!.id;

    final data = await supabase
        .from('user_profiles')
        .select('id, username')
        .neq('id', currentUserId)
        .neq('username', '')
        .not('username', 'is', null);

    final users = data
        .map<UserProfile>
        (
          (row) => UserProfile.fromMap(row),
        )
        .where
        (
          (user) => !widget.selectedPlayers.any
          (
            (player) => player.id == user.id,
          ),
        )
        .toList();

    if (!mounted)
    {
      return;
    }

    if (users.isEmpty)
    {
      setState
      (
        ()
        {
          loading = false;
        },
      );

      ScaffoldMessenger.of(context).showSnackBar
      (
        const SnackBar(content: Text("No available random players")),
      );

      return;
    }

    users.shuffle();

    setState
    (
      ()
      {
        selectedUser = users.first;
        controller.text = selectedUser!.username;
        results = [];
        loading = false;
      },
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return AlertDialog
    (
      title: const Center(child: Text("Add Player")),

      content: SizedBox
      (
        width: 300,
        child: Column
        (
          mainAxisSize: MainAxisSize.min,
          children:
          [
            FancySearchBar
            (
              controller: controller,
              hintText: "Search...",
              onChanged: (value)
              {
                searchUsers(value);
              },
            ),

            const SizedBox(height: 12),

            if (loading)
              const CircularProgressIndicator(),

            if (!loading)
              SizedBox
              (
                height: 150,
                child: ListView.builder
                (
                  itemCount: results.length,
                  itemBuilder: (context, index)
                  {
                    final user = results[index];

                    return ListTile
                    (
                      title: Text(user.username),
                      onTap: ()
                      {
                        setState
                        (
                          ()
                          {
                            selectedUser = user;
                            controller.text = user.username;
                            results = [];
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),

      actionsAlignment: MainAxisAlignment.center,

      actions:
      [
        TextButton
        (
          onPressed: ()
          {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),

        TextButton
        (
          onPressed: pickRandomUser,
          child: const Text("Random"),
        ),

        ElevatedButton
        (
          onPressed: ()
          {
            if (selectedUser == null)
            {
              return;
            }

            final currentUserId = supabase.auth.currentUser!.id;

            // Prevent adding yourself
            if (selectedUser!.id == currentUserId)
            {
              ScaffoldMessenger.of(context).showSnackBar
              (
                const SnackBar(content: Text("You cannot add yourself")),
              );
              return;
            }

            // Prevent duplicates
            final alreadyAdded = widget.selectedPlayers.any
            (
              (player) => player.id == selectedUser!.id,
            );

            if (alreadyAdded)
            {
              ScaffoldMessenger.of(context).showSnackBar
              (
                const SnackBar(content: Text("Player already added")),
              );
              return;
            }

            Navigator.pop(context, selectedUser);
          },

          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
