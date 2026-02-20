import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';
import '../styles/question_style.dart';

class QuestionScreen extends StatefulWidget {
  final Game game;

  const QuestionScreen({super.key, required this.game});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  static const int totalTime = 10;

  final supabase = Supabase.instance.client;
  Timer? timer;

  int timeLeft = totalTime;
  int currentQuestionIndex = 0;
  int roundScore = 0;
  bool isAnswered = false;

  List<Map<String, dynamic>> questions = [];
  List<String> currentAnswers = [];

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    final data = await supabase
        .from('game_questions')
        .select()
        .eq('game_id', widget.game.id)
        .eq('round', widget.game.currentRound)
        .limit(5);

    questions = List<Map<String, dynamic>>.from(data);
    buildAnswers();
    startTimer();
    setState(() {});
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
    timeLeft = totalTime;
    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft == 0) {
        t.cancel();
        nextQuestion();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void checkAnswer(String selected) {
    if (isAnswered) return;
    isAnswered = true;

    final q = questions[currentQuestionIndex];
    final correct = q['correct_answer'];

    if (selected == correct) {
      roundScore += widget.game.currentRound; // round 1 = 1pt, round 2 = 2pts, etc
    }

    Future.delayed(const Duration(milliseconds: 700), nextQuestion);
  }

  void nextQuestion() {
    timer?.cancel();
    isAnswered = false;

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        buildAnswers();
      });
      startTimer();
    } else {
      endTurn(roundScore);
    }
  }

  Future<void> endTurn(int roundScore) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;

    // 1. Copy current scores
    final updatedScores = Map<String, int>.from(widget.game.scores);

    final currentScore = updatedScores[userId] ?? 0;
    updatedScores[userId] = currentScore + roundScore;

    // 2. Compute next player
    final players = widget.game.playerIds;
    final currentIndex = players.indexOf(userId);

    String nextPlayerId;

    if (currentIndex == -1) {
      nextPlayerId = players.first;
    } else if (currentIndex == players.length - 1) {
      nextPlayerId = players.first;
    } else {
      nextPlayerId = players[currentIndex + 1];
    }

    // 3. Update game row
    await supabase.from('games').update({
      'scores': updatedScores,
      'current_turn_player_id': nextPlayerId,
    }).eq('id', widget.game.id);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = timeLeft / totalTime;
    final q = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: QuestionStyles.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 100),

                // QUESTION CARD
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

                // ANSWERS
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
              ],
            ),

            // TIMER
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
                      backgroundColor:
                          QuestionStyles.timerBackgroundColor,
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

  Widget buildAnswerButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => checkAnswer(text),
        style: QuestionStyles.answerButtonStyle,
        child: Text(text, style: QuestionStyles.answerTextStyle),
      ),
    );
  }
}