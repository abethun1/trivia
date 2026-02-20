class UserProfile
{
  final String id;
  final String username;
  final String rank;
  final String top_category;
  final int correctAnswers;

  UserProfile
  (
    {
      required this.id,
      required this.username,
      required this.rank,
      required this.top_category,
      required this.correctAnswers,
    }
  );

  factory UserProfile.fromMap(Map<String, dynamic> map)
  {
    return UserProfile
    (
      id: map['id'] as String,
      username: map['username'] as String,
      rank: (map['rank'] ?? '') as String,
      top_category: (map['top_category'] ?? '') as String,
      correctAnswers: (map['correct_answers'] ?? 0) as int,
    );
  }
}
