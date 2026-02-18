class Game {
  final List<String> players;
  final List<String> categories;
  final DateTime createdAt;
  int   roundNumber; 

  Game({
    required this.players,
    required this.categories,
    required this.createdAt,
    this.roundNumber = 0,
  });

  Map<String, dynamic> toJson() => {
    "players": players,
    "categories": categories,
    "createdAt": createdAt.toIso8601String(),
    "roundNumber": roundNumber,
  };

  static Game fromJson(Map<String, dynamic> json) {
    return Game(
      players: List<String>.from(json["players"]),
      categories: List<String>.from(json["categories"]),
      createdAt: DateTime.parse(json["createdAt"]),
      roundNumber: int.parse(json["roundNumber"]),
    );
  }
}
