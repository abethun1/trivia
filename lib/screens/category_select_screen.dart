import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Models
import '../models/user_profile.dart';
import '../models/game.dart';
import '../widgets/app_background.dart';
import '../widgets/fancy_search_bar.dart';

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
              onPressed: () async
              {
                final gameDraft = Game
                (
                  id: '',
                  creatorId: supabase.auth.currentUser!.id,
                  playerIds:
                  [
                    supabase.auth.currentUser!.id,
                    widget.players!.first.id,
                  ],
                  acceptedPlayers:
                  {
                    supabase.auth.currentUser!.id : true,
                    widget.players!.first.id : false,
                  },
                  playerCategories:
                  {
                    supabase.auth.currentUser!.id : selected.toList(),
                  },
                  scores:
                  {
                    supabase.auth.currentUser!.id : 0,
                    widget.players!.first.id : 0,
                  },
                  currentRound: 0,
                  currentTurnPlayerId: supabase.auth.currentUser!.id,
                  status: 'pending',
                  createdAt: DateTime.now(),
                );

                Navigator.pop(dialogContext);
                Navigator.pop(screenContext, gameDraft);
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
                fetchCategories(query: value);
              },
            ),
          ),

          const SizedBox(height: 12),

          Padding
          (
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container
            (
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration
              (
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFADC7F7), width: 2),
              ),
              child: Column
              (
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                [
                  Text("Selected Categories (${selected.length}/5)"),
                  const SizedBox(height: 8),
                  if (selected.isEmpty)
                    const Text("No categories selected"),
                  if (selected.isNotEmpty)
                    Wrap
                    (
                      spacing: 8,
                      runSpacing: 8,
                      children: selected.map((cat)
                      {
                        return ElevatedButton.icon
                        (
                          onPressed: () => toggle(cat),
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(cat),
                          style: ElevatedButton.styleFrom
                          (
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Text("Available Categories"),
          const SizedBox(height: 8),

          if (loading)
            const Expanded
            (
              child: Center(child: CircularProgressIndicator()),
            ),

          if (!loading)
            Expanded
            (
              child: ListView.separated
              (
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index)
                {
                  final cat = categories[index];
                  final isSelected = selected.contains(cat);

                  return ElevatedButton
                  (
                    style: ElevatedButton.styleFrom
                    (
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: isSelected
                          ? const Color(0xFFD6E6FF)
                          : null,
                    ),
                    onPressed: () => toggle(cat),
                    child: Row
                    (
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                      [
                        Expanded
                        (
                          child: Text
                          (
                            cat,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon
                        (
                          isSelected
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          Padding
          (
            padding: const EdgeInsets.all(12),
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
          ),
            ],
          ),
        ),
      ),
    );
  }
}
