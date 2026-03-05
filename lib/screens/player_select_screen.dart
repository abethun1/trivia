import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/game.dart';

//Screen
import 'category_select_screen.dart';

import '../widgets/app_background.dart';
import '../widgets/fancy_search_bar.dart';

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
  final supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();
  bool loading = false;

  List<UserProfile> players = [];
  UserProfile? selectedOpponent;


  @override
  void initState()
  {
    super.initState();
    fetchPlayers();
  }

  Future<void> fetchPlayers({String query = ""}) async
  {
    setState
    (
      ()
      {
        loading = true;
      },
    );

    final data = await supabase
        .from('user_profiles')
        .select('id, username, rank, top_category, correct_answers')
        .neq('id', supabase.auth.currentUser!.id)
        .ilike('username', '%$query%')
        .limit(9);

    data.shuffle();
    
    setState
    (
      ()
      {
        players =
            data.map<UserProfile>((row) => UserProfile.fromMap(row)).toList();
        loading = false;
      },
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: Column
          (
            children:
            [
            const SizedBox(height: 8),

            Padding
            (
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: FancySearchBar
              (
                controller: searchController,
                hintText: "Search...",
                onChanged: (value)
                {
                  fetchPlayers(query: value);
                },
              ),
            ),

          const SizedBox(height: 24),

          // PLAYER CARDS
          Expanded
          (
            child: ListView.builder
            (
              itemCount: players.length,
              itemBuilder: (context, index)
              {
                final player = players[index];
                final isSelected = selectedOpponent?.id == player.id;

                return Padding
                (
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: ElevatedButton
                  (
                    style: ElevatedButton.styleFrom
                    (
                      minimumSize: const Size(double.infinity, 70),
                      backgroundColor: isSelected ? Colors.green : null,
                    ),
                    onPressed: ()
                    {
                      setState
                      (
                        ()
                        {
                          selectedOpponent = player;
                        },
                      );
                    },
                    child: Text
                    (
                      player.username,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w100),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Padding
          (
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row
            (
              children:
              [
                Expanded
                (
                  child: ElevatedButton
                  (
                    onPressed: ()
                    {
                      Navigator.pop(context);
                    },
                    child: const Text("Back"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded
                (
                  child: ElevatedButton
                  (
                    onPressed: selectedOpponent == null
                        ? null
                        : () async
                          {
                            final game = await Navigator.push<Game>(
                              
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategorySelectScreen(
                                  players:
                                  [
                                    selectedOpponent!,
                                  ],
                                ),
                              ),
                            );

                            if (game != null)
                            {
                              if (!context.mounted) return;
                              Navigator.pop(context, game);
                            }
                          },
                    child: const Text("Next"),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
