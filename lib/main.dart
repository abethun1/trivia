import 'package:flutter/material.dart';

//Screens
import 'screens/login_screen.dart';
import 'screens/loading_screen.dart';

//Packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  
  await Supabase.initialize
  (
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const TriviaApp());
}

class TriviaApp extends StatelessWidget 
{
  const TriviaApp({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return MaterialApp
    (
      debugShowCheckedModeBanner: false,
      title: "Trivia Game",
      theme: ThemeData
      (
        textTheme: GoogleFonts.fredokaTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget 
{
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) 
  {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) 
    {
      return const LoginScreen();
    } 
    else 
    {
      return const LoadingScreen();
    }
  }
}
