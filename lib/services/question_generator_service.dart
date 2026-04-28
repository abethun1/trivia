import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/trivia_category_map.dart';
import '../utils/html_entity_decoder.dart';

const int finalRoundNumber = 3;

Future<String> _getToken() async {
  final res = await http.get(
    Uri.parse("https://opentdb.com/api_token.php?command=request"),
  );
  final data = jsonDecode(res.body);
  return data['token'];
}

Future<List<Map<String, dynamic>>> generateQuestionsForCategories({
  required List<String> categoryNames,
  required int round,
  int? questionTargetCountOverride,
  List<String>? allowedDifficultiesOverride,
}) async {
  final random = Random();

  final sanitizedCategories = categoryNames
      .where((name) => triviaCategoryMap.containsKey(name))
      .toSet()
      .toList();
  if (sanitizedCategories.isEmpty) {
    throw Exception('No categories configured for question generation.');
  }

  final token = await _getToken();

  final List<Map<String, dynamic>> rows = [];
  final Set<String> seenQuestions = {};
  final isFinalRound = round >= finalRoundNumber;

  List<String> allowedDifficulties = allowedDifficultiesOverride ?? const [];
  if (allowedDifficulties.isEmpty) {
    if (round == 1) {
      allowedDifficulties = ['easy', 'medium'];
    } else if (round == 2) {
      allowedDifficulties = ['medium', 'hard'];
    } else {
      allowedDifficulties = ['medium'];
    }
  }

  final questionTargetCount =
      questionTargetCountOverride ?? (isFinalRound ? 1 : 5);
  final maxAttempts = questionTargetCount * 40;
  var attempts = 0;

  while (rows.length < questionTargetCount && attempts < maxAttempts) {
    attempts++;
    await Future.delayed(const Duration(seconds: 1));

    final categoryName =
        sanitizedCategories[random.nextInt(sanitizedCategories.length)];
    final categoryId = triviaCategoryMap[categoryName];
    if (categoryId == null) continue;

    final difficulty =
        allowedDifficulties[random.nextInt(allowedDifficulties.length)];

    final useMultipleChoice = !isFinalRound;
    final questionTypeParam = useMultipleChoice ? "&type=multiple" : "";
    final url =
        "https://opentdb.com/api.php?amount=1"
        "$questionTypeParam"
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
      "category": decodeHtmlEntities(q['category'] as String),
      "difficulty": q['difficulty'],
      "question": decodeHtmlEntities(q['question'] as String),
      "correct_answer": decodeHtmlEntities(q['correct_answer'] as String),
      "wrong_answers": List<String>.from(q['incorrect_answers'])
          .map(decodeHtmlEntities)
          .toList(),
    });
  }

  if (rows.length < questionTargetCount) {
    throw Exception(
      'Unable to generate enough questions. Generated ${rows.length} of $questionTargetCount.',
    );
  }

  return rows;
}

Future<void> generateRoundQuestions({
  required String gameId,
  required int round,
  Map<String, List<String>>? playerCategoriesOverride,
  int? questionTargetCountOverride,
  List<String>? allowedDifficultiesOverride,
}) async {
  final supabase = Supabase.instance.client;
  final Map<String, dynamic> playerCategories;
  if (playerCategoriesOverride != null) {
    playerCategories = playerCategoriesOverride;
  } else {
    final game = await supabase
        .from('games')
        .select('player_categories')
        .eq('id', gameId)
        .single();
    playerCategories = game['player_categories'];
  }

  final categoryNames = playerCategories.values
      .expand((list) => List<String>.from(list))
      .toSet()
      .toList();
  final questions = await generateQuestionsForCategories(
    categoryNames: categoryNames,
    round: round,
    questionTargetCountOverride: questionTargetCountOverride,
    allowedDifficultiesOverride: allowedDifficultiesOverride,
  );

  final rows = questions
      .map((q) => {
            "game_id": gameId,
            "round": round,
            "category": q["category"],
            "difficulty": q["difficulty"],
            "question": q["question"],
            "correct_answer": q["correct_answer"],
            "wrong_answers": q["wrong_answers"],
          })
      .toList();

  await supabase.from('game_questions').insert(rows);
}
