import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/trivia_category_map.dart';

const int finalRoundNumber = 3;

Future<String> _getToken() async {
  final res = await http.get(
    Uri.parse("https://opentdb.com/api_token.php?command=request"),
  );
  final data = jsonDecode(res.body);
  return data['token'];
}

Future<void> generateRoundQuestions({
  required String gameId,
  required int round,
}) async {
  final supabase = Supabase.instance.client;
  final random = Random();

  final game = await supabase
      .from('games')
      .select('player_categories')
      .eq('id', gameId)
      .single();

  final Map<String, dynamic> playerCategories = game['player_categories'];

  final categoryNames = playerCategories.values
      .expand((list) => List<String>.from(list))
      .toSet()
      .toList();

  final token = await _getToken();

  final List<Map<String, dynamic>> rows = [];
  final Set<String> seenQuestions = {};

  List<String> allowedDifficulties;
  if (round == 1) {
    allowedDifficulties = ['easy', 'medium'];
  } else if (round == 2) {
    allowedDifficulties = ['medium', 'hard'];
  } else {
    allowedDifficulties = ['hard'];
  }

  final questionTargetCount = round >= finalRoundNumber ? 1 : 5;

  while (rows.length < questionTargetCount) {
    await Future.delayed(const Duration(seconds: 1));

    final categoryName = categoryNames[random.nextInt(categoryNames.length)];
    final categoryId = triviaCategoryMap[categoryName];
    if (categoryId == null) continue;

    final difficulty =
        allowedDifficulties[random.nextInt(allowedDifficulties.length)];

    final url =
        "https://opentdb.com/api.php?amount=1&type=multiple"
        "&category=$categoryId"
        "&difficulty=$difficulty"
        "&token=$token";

    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) continue;

    final data = jsonDecode(res.body);
    if (data['response_code'] != 0) continue;

    final q = data['results'][0];

    if (seenQuestions.contains(q['question'])) continue;
    seenQuestions.add(q['question']);

    rows.add({
      "game_id": gameId,
      "round": round,
      "category": q['category'],
      "difficulty": q['difficulty'],
      "question": q['question'],
      "correct_answer": q['correct_answer'],
      "wrong_answers": List<String>.from(q['incorrect_answers']),
    });
  }

  await supabase.from('game_questions').insert(rows);
}
