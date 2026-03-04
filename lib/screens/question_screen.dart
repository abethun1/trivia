import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dialogs/game_score_dialog.dart';
import '../models/game.dart';
import '../services/question_generator_service.dart';
import '../styles/question_style.dart';
import '../utils/html_entity_decoder.dart';

class QuestionScreen extends StatefulWidget {
  final Game game;

  const QuestionScreen({super.key, required this.game});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  static const int normalQuestionTime = 10;
  static const int finalQuestionTime = 20;

  final supabase = Supabase.instance.client;
  final TextEditingController betController = TextEditingController();
  final TextEditingController finalAnswerController = TextEditingController();
  Timer? timer;

  int timeLeft = normalQuestionTime;
  int currentQuestionIndex = 0;
  int roundScore = 0;
  int correctAnswersThisTurn = 0;
  int? finalBetAmount;

  bool loadingQuestions = true;
  bool revealAnswers = false;
  bool advanceScheduled = false;
  bool finalRoundStarted = false;

  String? selectedAnswer;
  String? betErrorText;

  List<Map<String, dynamic>> questions = [];
  List<String> currentAnswers = [];

  bool get isFinalRound => widget.game.currentRound == finalRoundNumber;
  int get timerDuration => isFinalRound ? finalQuestionTime : normalQuestionTime;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    timer?.cancel();
    betController.dispose();
    finalAnswerController.dispose();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    final questionCount = isFinalRound ? 1 : 5;

    final data = await supabase
        .from('game_questions')
        .select()
        .eq('game_id', widget.game.id)
        .eq('round', widget.game.currentRound)
        .limit(questionCount);

    questions = List<Map<String, dynamic>>.from(data)
        .map<Map<String, dynamic>>((row) {
      final decoded = Map<String, dynamic>.from(row);
      decoded['category'] = decodeHtmlEntities((row['category'] ?? '').toString());
      decoded['question'] = decodeHtmlEntities((row['question'] ?? '').toString());
      decoded['correct_answer'] =
          decodeHtmlEntities((row['correct_answer'] ?? '').toString());

      final wrongRaw = row['wrong_answers'] as List<dynamic>? ?? [];
      decoded['wrong_answers'] = wrongRaw
          .map((item) => decodeHtmlEntities(item.toString()))
          .toList();
      return decoded;
    }).toList();

    if (!mounted) return;
    setState(() {
      loadingQuestions = false;
    });

    if (questions.isEmpty) {
      return;
    }

    if (isFinalRound) {
      return;
    }

    buildAnswers();
    startTimer();
  }

  void buildAnswers() {
    final q = questions[currentQuestionIndex];
    currentAnswers = [
      q['correct_answer'],
      ...List<String>.from(q['wrong_answers']),
    ];
    currentAnswers.shuffle(Random());
  }

  void startTimer() {
    timeLeft = timerDuration;
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft == 0) {
        t.cancel();
        onTimeExpired();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void onTimeExpired() {
    if (revealAnswers || questions.isEmpty) return;

    if (isFinalRound) {
      submitTypedAnswer(finalAnswerController.text);
      return;
    }

    setState(() {
      revealAnswers = true;
      selectedAnswer = null;
    });

    scheduleAdvance();
  }

  int pointsForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 0;
    }
  }

  void scheduleAdvance() {
    if (advanceScheduled) return;
    advanceScheduled = true;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      nextQuestion();
    });
  }

  String normalizeAnswer(String value) {
    return value.trim().toLowerCase();
  }

  bool isTypedAnswerCorrect(String typed, String correct) {
    return normalizeAnswer(typed).isNotEmpty &&
        normalizeAnswer(typed) == normalizeAnswer(correct);
  }

  void checkAnswer(String selected) {
    if (revealAnswers || isFinalRound) return;
    timer?.cancel();

    final q = questions[currentQuestionIndex];
    final correct = q['correct_answer'] as String;
    final difficulty = (q['difficulty'] ?? '').toString();

    if (selected == correct) {
      roundScore += pointsForDifficulty(difficulty);
      correctAnswersThisTurn++;
    }

    setState(() {
      selectedAnswer = selected;
      revealAnswers = true;
    });

    scheduleAdvance();
  }

  void submitTypedAnswer(String rawInput) {
    if (revealAnswers || !isFinalRound || questions.isEmpty) return;
    timer?.cancel();

    final q = questions[currentQuestionIndex];
    final correct = q['correct_answer'] as String;
    final typed = rawInput.trim();
    final wager = finalBetAmount ?? 0;
    final isCorrect = isTypedAnswerCorrect(typed, correct);

    if (isCorrect) {
      roundScore += wager;
      correctAnswersThisTurn++;
    } else {
      roundScore -= wager;
    }

    setState(() {
      selectedAnswer = typed;
      revealAnswers = true;
    });

    scheduleAdvance();
  }

  void nextQuestion() {
    timer?.cancel();

    if (!isFinalRound && currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        revealAnswers = false;
        selectedAnswer = null;
        advanceScheduled = false;
        buildAnswers();
      });
      startTimer();
      return;
    }

    showTurnSummaryAndExit();
  }

  int totalPossiblePointsForTurn() {
    if (isFinalRound) {
      return finalBetAmount ?? 0;
    }

    return questions.fold<int>(
      0,
      (sum, q) => sum + pointsForDifficulty((q['difficulty'] ?? '').toString()),
    );
  }

  Future<void> showTurnSummaryAndExit() async {
    if (!mounted) return;

    final userId = supabase.auth.currentUser!.id;
    final currentTotal = widget.game.scores[userId] ?? 0;
    final finalTotalScore = currentTotal + roundScore;
    final possiblePoints = totalPossiblePointsForTurn();
    final finalizeFuture = endTurn(roundScore, correctAnswersThisTurn);

    await showTurnScoreDialog(
      context: context,
      finalizeFuture: finalizeFuture,
      earnedPoints: isFinalRound ? finalTotalScore : roundScore,
      possiblePoints: isFinalRound ? null : possiblePoints,
      scoreLabel: isFinalRound ? "Final Score" : "Score",
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  Color getAnswerBackground(String answerText) {
    if (!revealAnswers || questions.isEmpty) {
      return Colors.white;
    }

    final correct = questions[currentQuestionIndex]['correct_answer'] as String;
    if (answerText == correct) {
      return Colors.green;
    }

    final pickedWrong = selectedAnswer != null && selectedAnswer != correct;
    if (pickedWrong && answerText == selectedAnswer) {
      return Colors.red;
    }

    return Colors.white;
  }

  Color getAnswerTextColor(String answerText) {
    final bg = getAnswerBackground(answerText);
    return bg == Colors.white ? Colors.black : Colors.white;
  }

  Future<void> incrementCorrectAnswers(String userId, int incrementBy) async {
    if (incrementBy <= 0) return;

    final row = await supabase
        .from('user_profiles')
        .select('correct_answers')
        .eq('id', userId)
        .single();

    final currentRaw = row['correct_answers'];
    final currentValue = currentRaw is int
        ? currentRaw
        : (currentRaw is num ? currentRaw.toInt() : 0);

    await supabase
        .from('user_profiles')
        .update({'correct_answers': currentValue + incrementBy})
        .eq('id', userId);
  }

  Future<void> endTurn(int earnedScore, int correctAnswersCount) async {
    final userId = supabase.auth.currentUser!.id;
    final updatedScores = Map<String, int>.from(widget.game.scores);

    final currentScore = updatedScores[userId] ?? 0;
    updatedScores[userId] = currentScore + earnedScore;

    final players = widget.game.playerIds;
    final currentIndex = players.indexOf(userId);

    if (players.isEmpty) return;

    if (currentIndex == -1) {
      await supabase.from('games').update({
        'scores': updatedScores,
        'current_turn_player_id': players.first,
      }).eq('id', widget.game.id);
    } else {
      final isLastPlayerInRound = currentIndex == players.length - 1;

      if (!isLastPlayerInRound) {
        final nextPlayerId = players[currentIndex + 1];
        await supabase.from('games').update({
          'scores': updatedScores,
          'current_turn_player_id': nextPlayerId,
        }).eq('id', widget.game.id);
      } else {
        final currentRound = widget.game.currentRound;

        if (currentRound >= finalRoundNumber) {
          await supabase.from('games').update({
            'scores': updatedScores,
            'status': 'ended',
            'current_turn_player_id': players.first,
          }).eq('id', widget.game.id);
        } else {
          final nextRound = currentRound + 1;

          await supabase.from('games').update({
            'scores': updatedScores,
            'current_round': nextRound,
            'current_turn_player_id': players.first,
          }).eq('id', widget.game.id);

          await generateRoundQuestions(
            gameId: widget.game.id,
            round: nextRound,
          );
        }
      }
    }

    await incrementCorrectAnswers(userId, correctAnswersCount);
  }

  int currentPlayerTotalScore() {
    final userId = supabase.auth.currentUser!.id;
    return widget.game.scores[userId] ?? 0;
  }

  int? parseBetValue() {
    return int.tryParse(betController.text.trim());
  }

  String? validateBet(int currentTotalScore) {
    final bet = parseBetValue();
    if (bet == null) return "Enter a valid integer";
    if (bet <= 0) return "Bet must be greater than 0";
    if (bet >= currentTotalScore) {
      return "Bet must be less than your total score";
    }
    return null;
  }

  void startFinalRoundQuestion() {
    final totalScore = currentPlayerTotalScore();
    final validationError = validateBet(totalScore);

    if (validationError != null) {
      setState(() {
        betErrorText = validationError;
      });
      return;
    }

    setState(() {
      finalBetAmount = parseBetValue();
      finalRoundStarted = true;
      betErrorText = null;
    });

    startTimer();
  }

  Widget buildFinalRoundSetup(Map<String, dynamic> q) {
    final totalScore = currentPlayerTotalScore();

    return Scaffold(
      backgroundColor: QuestionStyles.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Final Round",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                q['category']?.toString() ?? "Unknown Category",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: betController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Bet",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (betErrorText != null) {
                          setState(() {
                            betErrorText = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "/ $totalScore",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (betErrorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  betErrorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (totalScore <= 1) ...[
                const SizedBox(height: 8),
                const Text(
                  "You need at least 2 total points to place a valid bet.",
                  style: TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: totalScore <= 1 ? null : startFinalRoundQuestion,
                child: const Text("Go To Question"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFinalAnswerSection(Map<String, dynamic> q) {
    final correct = q['correct_answer']?.toString() ?? "";
    final typed = selectedAnswer ?? "";
    final typedCorrect = isTypedAnswerCorrect(typed, correct);
    final hasTypedAnswer = typed.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextField(
            controller: finalAnswerController,
            readOnly: revealAnswers,
            decoration: const InputDecoration(
              hintText: "Type your answer",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: revealAnswers || finalAnswerController.text.trim().isEmpty
                  ? null
                  : () => submitTypedAnswer(finalAnswerController.text),
              child: const Text("Submit"),
            ),
          ),
          if (revealAnswers) ...[
            const SizedBox(height: 16),
            if (hasTypedAnswer)
              Text(
                typedCorrect ? "Your answer is correct." : "Your answer is incorrect.",
                style: TextStyle(
                  color: typedCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const Text(
                "No answer submitted before time ran out.",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 8),
            Text(
              "Correct answer: $correct",
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildAnswerButton(String text) {
    final backgroundColor = getAnswerBackground(text);
    final textColor = getAnswerTextColor(text);

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => checkAnswer(text),
        style: QuestionStyles.answerButtonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(backgroundColor),
          foregroundColor: WidgetStatePropertyAll(textColor),
        ),
        child: Text(
          text,
          style: QuestionStyles.answerTextStyle.copyWith(color: textColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingQuestions) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text("No questions found for this round."),
        ),
      );
    }

    final q = questions[currentQuestionIndex];

    if (isFinalRound && !finalRoundStarted) {
      return buildFinalRoundSetup(q);
    }

    final progress = timeLeft / timerDuration;

    return Scaffold(
      backgroundColor: QuestionStyles.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 6,
                    shape: QuestionStyles.questionCardShape,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.20,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text(
                        q['question'],
                        textAlign: TextAlign.center,
                        style: QuestionStyles.questionTextStyle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (!isFinalRound)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: currentAnswers.map((a) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildAnswerButton(a),
                        );
                      }).toList(),
                    ),
                  ),
                if (isFinalRound) buildFinalAnswerSection(q),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 55,
                    height: 55,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: QuestionStyles.timerBackgroundColor,
                      color: QuestionStyles.timerColor,
                    ),
                  ),
                  Text(
                    "$timeLeft",
                    style: QuestionStyles.timerTextStyle,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
