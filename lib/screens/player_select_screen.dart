import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/game.dart';

//Screen
import 'category_select_screen.dart';

//Style
import '../styles/player_select_styles.dart';

//Dialogs
import '../dialogs/player_search_dialog.dart';

class PlayerSelectScreen extends StatefulWidget
{
  const PlayerSelectScreen({super.key});

  @override
  State<PlayerSelectScreen> createState()
  {
    return _PlayerSelectScreenState();
  }
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen>
{
  static const int maxPlayers = 3;

  List<UserProfile> selectedPlayers = [];

  void addPlayerSlot(UserProfile user)
  {
    if (selectedPlayers.length < maxPlayers)
    {
      setState
      (
        ()
        {
          selectedPlayers.add(user);
        },
      );
    }
  }

  void removePlayerSlot(int index)
  {
    setState
    (
      ()
      {
        selectedPlayers.removeAt(index);
      },
    );
  }

  Future<void> openPlayerPicker() async
  {
    final selectedUser = await showDialog<UserProfile>
    (
      context: context,
      builder: (context)
      {
        return PlayerSearchDialog(selectedPlayers: selectedPlayers);
      },
    );

    if (selectedUser != null)
    {
      addPlayerSlot(selectedUser);
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar(title: const Text("Select Players")),
      body: Column
      (
        children:
        [
          const SizedBox(height: 16),

          // ADD PLAYER BUTTON
          Row
          (
            mainAxisAlignment: MainAxisAlignment.center,
            children:
            [
              ElevatedButton
              (
                onPressed: selectedPlayers.length >= maxPlayers
                    ? null
                    : openPlayerPicker,
                child: const Text("+"),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // PLAYER CARDS
          Expanded
          (
            child: ListView.builder
            (
              itemCount: selectedPlayers.length,
              itemBuilder: (context, index)
              {
                final player = selectedPlayers[index];

                return Padding
                (
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Stack
                  (
                    children:
                    [
                      ElevatedButton
                      (
                        style: ElevatedButton.styleFrom
                        (
                          minimumSize: const Size(double.infinity, 70),
                        ),
                        onPressed: () {},
                        child: Text
                        (
                          player.username,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),

                      // REMOVE BUTTON
                      Positioned
                      (
                        right: 8,
                        top: 8,
                        child: IconButton
                        (
                          icon: const Icon(Icons.remove_circle),
                          onPressed: ()
                          {
                            removePlayerSlot(index);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton
          (
            onPressed: selectedPlayers.isEmpty
                ? null
                : () async
                  {
                    final game = await Navigator.push<Game>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategorySelectScreen(
                          players: List.from(selectedPlayers),
                        ),
                      ),
                    );
                    
                    if (game != null)
                    {
                      Navigator.pop(context, game);
                    }
                  },
            child: const Text("Next"),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
