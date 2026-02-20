import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Models
import '../models/user_profile.dart';
import '../models/game.dart';

class CategorySelectScreen extends StatefulWidget
{
  final List<UserProfile>? players;
  final String? gameId;
  final bool isJoining;

  const CategorySelectScreen
  (
    {
      super.key,
      this.players,
      this.gameId,
      this.isJoining = false,
    }
  );

  @override
  State<CategorySelectScreen> createState()
  {
    return _CategorySelectScreenState();
  }
}

class _CategorySelectScreenState extends State<CategorySelectScreen>
{
  final supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<String> categories = [];
  final Set<String> selected = {};
  bool loading = false;

  
  List<String> playerUsernames = [];

  @override
  void initState()
  {
    super.initState();
    fetchCategories();

    
    if (widget.isJoining)
    {
      fetchPlayers();
    }
  }

  
  Future<void> fetchPlayers() async
  {
    final gameRow = await supabase
        .from('games')
        .select()
        .eq('id', widget.gameId!)
        .single();

    final g = Game.fromJson(gameRow);

    final users = await supabase
        .from('user_profiles')
        .select('username')
        .inFilter('id', g.playerIds);

    setState
    (
      ()
      {
        playerUsernames =
            users.map<String>((u) => u["username"] as String).toList();
      },
    );
  }

  Future<void> fetchCategories({String query = ""}) async
  {
    setState
    (
      ()
      {
        loading = true;
      },
    );

    final data = await supabase
        .from('categories')
        .select('category_name')
        .ilike('category_name', '%$query%');
    setState
    (
      ()
      {
        categories =
            data.map<String>((row) => row['category_name'] as String).toList();
        loading = false;
      },
    );
  }

  void toggle(String cat)
  {
    setState
    (
      ()
      {
        if (selected.contains(cat))
        {
          selected.remove(cat);
        }
        else if (selected.length < 5)
        {
          selected.add(cat);
        }
      },
    );
  }

  //================ HOST CONFIRM =================
  void showHostConfirmation()
  {
    final screenContext = context;

    showDialog
    (
      context: context,
      builder: (dialogContext)
      {
        return AlertDialog
        (
          title: const Center(child: Text("Create Game?")),
          content: Column
          (
            mainAxisSize: MainAxisSize.min,
            children:
            [
              const Text("Players"),
              const SizedBox(height: 8),
              Column
              (
                children: widget.players!
                    .map((p) => Text(p.username))
                    .toList(),
              ),
              const Divider(),
              const Text("Categories"),
              Column
              (
                children: selected.map((c) => Text(c)).toList(),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions:
          [
            TextButton
            (
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton
            (
              onPressed: ()
              {
                final game = Game
                (
                  id: '',
                  creatorId: supabase.auth.currentUser!.id,
                  playerIds: widget.players!.map((p) => p.id).toList(),
                  acceptedPlayers:
                  {
                    for (final p in widget.players!) p.id : false,
                  },
                  playerCategories:
                  {
                    supabase.auth.currentUser!.id : selected.toList(),
                  },
                  scores:
                  {
                    for (final p in widget.players!) p.id : 0,
                  },
                  currentRound: 1,
                  currentTurnPlayerId: supabase.auth.currentUser!.id,
                  status: 'pending',
                  createdAt: DateTime.now(),
                );

                Navigator.pop(dialogContext);
                Navigator.pop(screenContext, game);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  //================ JOIN CONFIRM =================
  void showJoinConfirmation()
{
  final screenContext = context;

  showDialog
  (
    context: context,
    builder: (dialogContext)
    {
      return AlertDialog
      (
        title: const Center(child: Text("Join Game?")),
        content: Column
        (
          mainAxisSize: MainAxisSize.min,
          children:
          [
            const Text("Your Categories"),
            Column
            (
              children: selected.map((c) => Text(c)).toList(),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions:
        [
          TextButton
          (
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton
          (
            onPressed: ()
            {
              Navigator.pop(dialogContext);
              Navigator.pop(screenContext, selected.toList());
            },
            child: const Text("Accept"),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar(title: const Text("Select Categories")),
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
                  fetchCategories(query: value);
                },
                decoration: const InputDecoration
                (
                  hintText: "Search categories",
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding
          (
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column
            (
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
              [
                const Text("Selected Categories"),
                const SizedBox(height: 6),
                Wrap
                (
                  spacing: 8,
                  children: selected.map((cat)
                  {
                    return Chip
                    (
                      label: Text(cat),
                      onDeleted: () => toggle(cat),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(),
          const Text("Available Categories"),

          if (loading)
            const CircularProgressIndicator(),

          if (!loading)
            Wrap
            (
              spacing: 8,
              children: categories.map((cat)
              {
                return ChoiceChip
                (
                  label: Text(cat),
                  selected: selected.contains(cat),
                  onSelected: (_) => toggle(cat),
                );
              }).toList(),
            ),

          const Spacer(),

          Padding
          (
            padding: const EdgeInsets.all(12),
            child: ElevatedButton
            (
              onPressed: selected.length == 5
                  ? (widget.isJoining
                        ? showJoinConfirmation
                        : showHostConfirmation)
                  : null,
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}
