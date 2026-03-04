class Game 
{
  final String id;
  final String creatorId;

  final List<String> playerIds;

  final Map<String, bool> acceptedPlayers; 
  final Map<String, List<String>> playerCategories;
  final Map<String, int> scores;

  int currentRound;
  String? currentTurnPlayerId;
  String status; // "pending", "active", "ended"

  final DateTime createdAt;

  Game
  (
    {
      required this.id,
      required this.creatorId,
      required this.playerIds,
      required this.acceptedPlayers,
      required this.playerCategories,
      required this.scores,
      required this.currentRound,
      required this.currentTurnPlayerId,
      required this.status,
      required this.createdAt,
    }
  );

  Map<String, dynamic> toJson() 
  {
    return {
      "id": id,
      "creator_id": creatorId,
      "player_ids": playerIds,
      "accepted_players": acceptedPlayers,
      "player_categories": playerCategories,
      "scores": scores,
      "current_round": currentRound,
      "current_turn_player_id": currentTurnPlayerId,
      "status": status,
      "created_at": createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson()
  {
    return {
      "creator_id": creatorId,
      "player_ids": playerIds,
      "accepted_players": acceptedPlayers,
      "player_categories": playerCategories,
      "scores": scores,
      "current_round": currentRound,
      "current_turn_player_id": currentTurnPlayerId,
      "status": status,
    };
  }

  static Game fromJson(Map<String, dynamic> json) 
  {
    return Game
    (
      id: json["id"],
      creatorId: json["creator_id"],
      playerIds: List<String>.from(json["player_ids"]),
      acceptedPlayers: Map<String, bool>.from(json["accepted_players"]),
      playerCategories: Map<String, List<String>>.from
      (
        (json["player_categories"] as Map).map
        (
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      scores: Map<String, int>.from(json["scores"]),
      currentRound: json["current_round"],
      currentTurnPlayerId: json["current_turn_player_id"],
      status: json["status"],
      createdAt: DateTime.parse(json["created_at"]),
    );
  }
}
