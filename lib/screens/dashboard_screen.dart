import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Models
import '../models/user_profile.dart';
import '../models/game.dart';

//Styles
import '../styles/dashboard_styles.dart';

//Screens
import 'player_select_screen.dart';
import 'settings_screen.dart';
import 'question_screen.dart';

//Dialogs
import '../dialogs/dashboard_dailogs.dart';
import '../dialogs/game_score_dialog.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/split_game_avatar.dart';

//Services
import '../services/question_generator_service.dart';

class DashboardScreen extends StatefulWidget
{
  final UserProfile userProfile;

  const DashboardScreen(
    {
      super.key,
      required this.userProfile,
    }
  );

  @override
  State<DashboardScreen> createState()
  {
    return _DashboardScreenState();
  }
}

class _DashboardScreenState extends State<DashboardScreen> 
{
  UserProfile fallbackProfile(String id)
  {
    return UserProfile.fromMap(
      {
        'id': id,
        'username': '?',
      },
    );
  }

  List<UserProfile> orderedPlayersForGame(
    Game game,
    Map<String, UserProfile> profilesById,
  )
  {
    final creator = profilesById[game.creatorId] ?? fallbackProfile(game.creatorId);

    final opponentId = game.playerIds.firstWhere(
      (id) => id != game.creatorId,
      orElse: () => game.creatorId,
    );
    final opponent = profilesById[opponentId] ?? fallbackProfile(opponentId);

    return [creator, opponent];
  }

  Widget buildGameAvatarButton(
    Game game,
    Map<String, UserProfile> profilesById, {
    VoidCallback? onTap,
  })
  {
    final players = orderedPlayersForGame(game, profilesById);

    final child = SplitGameAvatar(
      topLeftPlayer: players.first,
      bottomRightPlayer: players.last,
      size: DashboardStyles.gameCircleSize,
    );

    return Padding(
      padding: DashboardStyles.gameCirclePadding,
      child: GestureDetector(
        onTap: onTap,
        child: child,
      ),
    );
  }

  late UserProfile profile;

  @override
  void initState()
  {
    super.initState();
    profile = widget.userProfile;
  }

  Future<void> refreshUserProfile() async
  {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final data = await client
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .single();

    if (!mounted) return;

    setState(() {
      profile = UserProfile.fromMap(data);
    });
  }

  Map<String, List<Game>> bucketGames(List<Game> games, String userId)
  {
    final buckets = <String, List<Game>>
    {
      "request": [],
      "waiting": [],
      "yourTurn": [],
      "theirTurn": [],
      "ended": [],
    };

    for (final game in games)
    {
      final accepted = game.acceptedPlayers[userId] ?? false;
      final allAccepted = game.acceptedPlayers.values.every((v) => v == true);

      if (game.status == "ended")
      {
        buckets["ended"]!.add(game);
      }
      else if (!accepted)
      {
        buckets["request"]!.add(game);
      }
      else if (!allAccepted)
      {
        buckets["waiting"]!.add(game);
      }
      else if (game.currentTurnPlayerId == userId)
      {
        buckets["yourTurn"]!.add(game);
      }
      else
      {
        buckets["theirTurn"]!.add(game);
      }
    }

    return buckets;
  }

Future<void> onRequestTap(Game game) async
{
  final client = Supabase.instance.client;

  final profile = await client
      .from('user_profiles')
      .select('username')
      .eq('id', game.creatorId)
      .single();

  final hostUsername = profile["username"];

  if (!mounted) return;

  final result = await showInviteDialog(
    context: context,
    hostUsername: hostUsername,
    gameId: game.id,
  );

  if (result != null)
  {
    final userId = client.auth.currentUser!.id;

    final updatedAccepted =
        Map<String, bool>.from(game.acceptedPlayers);

    final updatedCategories =
        Map<String, List<String>>.from(game.playerCategories);

    updatedAccepted[userId] = true;
    updatedCategories[userId] = result;

    final allAccepted =
        updatedAccepted.values.every((v) => v == true);

    if (allAccepted)
    {
      // 1. Update game state
      await client.from('games').update(
      {
        "accepted_players": updatedAccepted,
        "player_categories": updatedCategories,
        "status": "active",
        "current_round": 1,
        "current_turn_player_id": game.creatorId,
      }).eq("id", game.id);

    if (!mounted) return;
    showGameCreatingDialog(context);

    await generateRoundQuestions
    (
      gameId: game.id,
      round: 1,
    );

    if (!mounted) return;
    Navigator.pop(context);
    }
    else
    {
      await client.from('games').update(
      {
        "accepted_players": updatedAccepted,
        "player_categories": updatedCategories,
      }).eq("id", game.id);
    }


    if (!mounted) return;
    setState(() {});
  }
}


  /**
   * Gets the info from the player select screen and the category select screen
   * as well as the user_profile of the current user to set up a game object
   * and store its values in the appropriate database table
   */
  Future<void> startNewGame(BuildContext context) async
  {
    final game = await Navigator.push<Game>
    (
      context,
      MaterialPageRoute(builder: (_) => const PlayerSelectScreen()),
    );

    if (game == null) return;

    final client = Supabase.instance.client;

    await client
        .from('games')
        .insert(game.toInsertJson());

    if (!mounted) return;
    setState(() {});
  }


/**
 * Gets all of the games that the current player is attached to
 */
Future<List<Game>> fetchMyGames() async
{
  final userId = Supabase.instance.client.auth.currentUser!.id;

  final data = await Supabase.instance.client
      .from('games')
      .select()
      .contains('player_ids', [userId]);

  final games =
      data.map<Game>((row) => Game.fromJson(row)).toList();

  return games;
}

Future<Map<String, UserProfile>> fetchProfilesForGames(List<Game> games) async
{
  final ids = <String>{};
  for (final game in games)
  {
    ids.addAll(game.playerIds);
  }

  if (ids.isEmpty)
  {
    return {};
  }

  final rows = await Supabase.instance.client
      .from('user_profiles')
      .select('id, username, rank, top_category, correct_answers, avatar_path, avatar_pending_path, avatar_status, avatar_color_hex')
      .inFilter('id', ids.toList());

  final map = <String, UserProfile>{};
  for (final row in rows)
  {
    final p = UserProfile.fromMap(row);
    map[p.id] = p;
  }

  return map;
}

Future<void> onEndedGameTap(Game game) async
{
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;

  final players = List<String>.from(game.playerIds);
  if (players.isEmpty)
  {
    return;
  }

  final profiles = await client
      .from('user_profiles')
      .select('id, username')
      .inFilter('id', players);

  final usernames = <String, String>{};
  for (final row in profiles)
  {
    usernames[row['id'] as String] = row['username'] as String;
  }

  final opponentId = players.firstWhere(
    (id) => id != userId,
    orElse: () => userId,
  );

  final currentUsername = usernames[userId] ?? profile.username;
  final opponentUsername = usernames[opponentId] ?? 'Opponent';

  final currentScore = game.scores[userId] ?? 0;
  final opponentScore = game.scores[opponentId] ?? 0;

  var winnerName = "Tie";
  if (game.scores.isNotEmpty)
  {
    final maxScore = game.scores.values.reduce((a, b) => a > b ? a : b);
    final winnerIds = game.scores.entries
        .where((entry) => entry.value == maxScore)
        .map((entry) => entry.key)
        .toList();

    if (winnerIds.length == 1)
    {
      winnerName = usernames[winnerIds.first] ?? "Unknown";
    }
  }

  if (!mounted) return;

  await showEndedGameScoreDialog(
    context: context,
    winnerName: winnerName,
    currentUsername: currentUsername,
    currentScore: currentScore,
    opponentUsername: opponentUsername,
    opponentScore: opponentScore,
  );
}
  
  Widget buildGameSection(
    String title,
    List<Game> games,
    Map<String, UserProfile> profilesById,
  )
  {
    if (games.isEmpty)
    {
      return Column
      (
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
        [
          Text(title, style: DashboardStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text("No games"),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
      [
        Text(title, style: DashboardStyles.sectionTitle),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: games
                .map((game) => buildGameAvatarButton(game, profilesById))
                .toList(),
          ),
        ),
      ],
    );
  }

  //================= NEW REQUEST SECTION =================
  Widget buildRequestSection(
    String title,
    List<Game> games,
    Map<String, UserProfile> profilesById,
  )
  {
    if (games.isEmpty)
    {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text("No games"),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DashboardStyles.sectionTitle),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: games
                .map(
                  (game) => buildGameAvatarButton(
                    game,
                    profilesById,
                    onTap: () => onRequestTap(game),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget buildYourTurnSection(
    String title,
    List<Game> games,
    Map<String, UserProfile> profilesById,
  ) {
    if (games.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text("No games"),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DashboardStyles.sectionTitle),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: games
                .map(
                  (game) => buildGameAvatarButton(
                    game,
                    profilesById,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuestionScreen(game: game),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget buildEndedSection(
    String title,
    List<Game> games,
    Map<String, UserProfile> profilesById,
  )
  {
    if (games.isEmpty)
    {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardStyles.sectionTitle),
          const SizedBox(height: 8),
          const Text("No games"),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DashboardStyles.sectionTitle),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: games
                .map(
                  (game) => buildGameAvatarButton(
                    game,
                    profilesById,
                    onTap: () => onEndedGameTap(game),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context)
  {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text("${profile.username} Dashboard")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children:
            [
              // TOP ROW
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: DashboardStyles.statsCardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                        [
                          Text("Rank: ${profile.rank}", style: DashboardStyles.statsText),
                          Text("Top Category: ${profile.top_category}", style: DashboardStyles.statsText),
                          Text("Correct Answers: ${profile.correctAnswers}", style: DashboardStyles.statsText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector
                  (
                    onTap: () async
                    {
                      final updatedProfile = await Navigator.push<UserProfile>
                      (
                        context,
                        MaterialPageRoute
                        (
                          builder: (_) => SettingsScreen(userProfile: profile),
                        ),
                      );

                      if (!mounted) return;

                      if (updatedProfile != null)
                      {
                        setState(() {
                          profile = updatedProfile;
                        });
                      }
                      else
                      {
                        await refreshUserProfile();
                      }
                    },
                    child: Column
                    (
                      children: 
                      [
                        ProfileAvatar
                        (
                          username: profile.username,
                          avatarPath: profile.avatarPath,
                          avatarStatus: profile.avatarStatus,
                          avatarColorHex: profile.avatarColorHex,
                          radius: 38,
                        ),

                        const SizedBox(height: 6),
                        Text
                        (
                          profile.username,
                          style: const TextStyle
                          (
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                      ]
                    )

                  ),
                ],
              ),

              const SizedBox(height: 20),

              // START GAME BUTTON
              SizedBox
              (
                width: size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () => startNewGame(context),
                  style: DashboardStyles.startGameButtonStyle,
                  child: const Text("Start New Game", style: TextStyle(fontSize: 20)),
                ),
              ),

              const SizedBox(height: 24),

              FutureBuilder<List<Game>>
              (
                future: fetchMyGames(),
                builder: (context, snapshot)
                {
                  if (!snapshot.hasData)
                  {
                    return const CircularProgressIndicator();
                  }

                  final games = snapshot.data!;

                  return FutureBuilder<Map<String, UserProfile>>(
                    future: fetchProfilesForGames(games),
                    builder: (context, profilesSnapshot)
                    {
                      if (!profilesSnapshot.hasData)
                      {
                        return const CircularProgressIndicator();
                      }

                      final profilesById = profilesSnapshot.data!;
                      final userId = Supabase.instance.client.auth.currentUser!.id;
                      final buckets = bucketGames(games, userId);
                      final requestGames = buckets["request"]!;
                      final waitingGames = buckets["waiting"]!;
                      final yourTurnGames = buckets["yourTurn"]!;
                      final theirTurnGames = buckets["theirTurn"]!;
                      final endedGames = buckets["ended"]!;

                      return Column
                      (
                        children:
                        [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: buildYourTurnSection(
                              "Your Turn",
                              yourTurnGames,
                              profilesById,
                            ),
                          ),
                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: buildGameSection(
                              "Their Turn",
                              theirTurnGames,
                              profilesById,
                            ),
                          ),
                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: buildGameSection(
                              "Waiting",
                              waitingGames,
                              profilesById,
                            ),
                          ),
                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: buildRequestSection(
                              "Request",
                              requestGames,
                              profilesById,
                            ),
                          ),
                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: buildEndedSection(
                              "Ended Games",
                              endedGames,
                              profilesById,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
