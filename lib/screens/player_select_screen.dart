import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  static const int maxPlayers = 1;

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
        .limit(6);

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
      appBar: AppBar(title: const Text("Select Players")),
      body: Column
      (
        children:
        [
          const SizedBox(height: 8),

          Padding
          (
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material
            (
              elevation: 3,
              borderRadius: BorderRadius.circular(30),
              child: TextField
              (
                controller: searchController,
                onChanged: (value)
                {
                  fetchPlayers(query: value);
                },
                decoration: const InputDecoration
                (
                  hintText: "Search for a Player",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
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
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton
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
