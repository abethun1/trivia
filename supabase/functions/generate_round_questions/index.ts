import { serve } from "https://deno.land/std/http/server.ts";
import OpenAI from "https://esm.sh/openai@4";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const openai = new OpenAI({
  apiKey: Deno.env.get("OPENAI_API_KEY")!,
});

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { gameId, round } = await req.json();

    if (!gameId || !round) {
      return new Response("Missing gameId or round", { status: 400 });
    }

    const supabase = createClient(supabaseUrl, serviceKey);

    const { data: game, error } = await supabase
      .from("games")
      .select("player_categories")
      .eq("id", gameId)
      .single();

    if (error) throw error;

    const categories = Object.values(game.player_categories).flat();

    const prompt = `
You are a quiz generator.

Using the following categories:
${categories.join(", ")}

Generate exactly 10 quiz questions.
Each question must include:
- question
- correct_answer
- wrong_answers (array of 3 plausible incorrect answers)
- difficulty (easy, medium, hard)

Output ONLY valid JSON:
[
  {
    "question": "...",
    "correct_answer": "...",
    "wrong_answers": ["...", "...", "..."],
    "difficulty": "easy|medium|hard"
  }
]
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4.1-mini",
      messages: [{ role: "user", content: prompt }],
      temperature: 0.7,
    });

    const questions = JSON.parse(completion.choices[0].message.content!);

    const inserts = questions.map((q: any) => ({
      game_id: gameId,
      round,
      question: q.question,
      correct_answer: q.correct_answer,
      wrong_answers: q.wrong_answers,
    }));

    const { error: insertError } = await supabase
      .from("game_questions")
      .insert(inserts);

    if (insertError) throw insertError;

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500 },
    );
  }
});
