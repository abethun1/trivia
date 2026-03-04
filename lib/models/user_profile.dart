class UserProfile
{
  final String id;
  final String username;
  final String rank;
  final String top_category;
  final int correctAnswers;
  final String? avatarPath;
  final String? avatarPendingPath;
  final String avatarStatus;
  final String avatarColorHex;

  UserProfile
  (
    {
      required this.id,
      required this.username,
      required this.rank,
      required this.top_category,
      required this.correctAnswers,
      required this.avatarPath,
      required this.avatarPendingPath,
      required this.avatarStatus,
      required this.avatarColorHex,
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
      avatarPath: map['avatar_path'] as String?,
      avatarPendingPath: map['avatar_pending_path'] as String?,
      avatarStatus: (map['avatar_status'] ?? 'approved') as String,
      avatarColorHex: (map['avatar_color_hex'] ?? '#D8B4FE') as String,
    );
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? rank,
    String? top_category,
    int? correctAnswers,
    String? avatarPath,
    String? avatarPendingPath,
    String? avatarStatus,
    String? avatarColorHex,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      rank: rank ?? this.rank,
      top_category: top_category ?? this.top_category,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      avatarPath: avatarPath ?? this.avatarPath,
      avatarPendingPath: avatarPendingPath ?? this.avatarPendingPath,
      avatarStatus: avatarStatus ?? this.avatarStatus,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
    );
  }
}
