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
    final buttonTextStyle = GoogleFonts.fredoka(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.6,
      shadows: const [
        Shadow(
          color: Color.fromARGB(120, 9, 57, 138),
          offset: Offset(0, 2),
          blurRadius: 2,
        ),
      ],
    );

    return MaterialApp
    (
      debugShowCheckedModeBanner: false,
      title: "Trivia Game",
      theme: ThemeData
      (
        useMaterial3: false,
        textTheme: GoogleFonts.fredokaTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFFD6DEED);
              }
              return const Color(0xFFF2F6FF);
            }),
            foregroundColor: const WidgetStatePropertyAll(Color(0xFF0E49A8)),
            shadowColor: const WidgetStatePropertyAll(Color(0x663B74D8)),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return 2;
              }
              if (states.contains(WidgetState.disabled)) {
                return 1;
              }
              return 8;
            }),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            side: const WidgetStatePropertyAll(
              BorderSide(
                color: Color(0xFFBCD2FF),
                width: 2,
              ),
            ),
            textStyle: WidgetStatePropertyAll(buttonTextStyle),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(Color(0xFF0E49A8)),
            textStyle: WidgetStatePropertyAll(
              GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                shadows: const [
                  Shadow(
                    color: Color.fromARGB(90, 9, 57, 138),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
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
