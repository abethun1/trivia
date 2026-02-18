import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class SettingsScreen extends StatelessWidget
{
  const SettingsScreen({super.key});

  void signOut(BuildContext context) async
  {
    await Supabase.instance.client.auth.signOut();
  
    if (!context.mounted) return;
  
    Navigator.pushAndRemoveUntil
    (
      context,
      MaterialPageRoute
      (
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
    );
  }
  
  Widget buildButton
  (
    {
      required String text,
      required VoidCallback onPressed,
    }
  )
  {
    return Padding
    (
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox
      (
        width: double.infinity,
        child: ElevatedButton
        (
          onPressed: onPressed,
          style: ElevatedButton.styleFrom
          (
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder
            (
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text
          (
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar(title: const Text("Settings")),
      body: Padding
      (
        padding: const EdgeInsets.all(24),
        child: Column
        (
          children:
          [
            buildButton
            (
              text: "Change Display Name",
              onPressed: ()
              {
                ScaffoldMessenger.of(context).showSnackBar
                (
                  const SnackBar(content: Text("Coming soon")),
                );
              },
            ),

            buildButton
            (
              text: "Change Avatar Pic",
              onPressed: ()
              {
                ScaffoldMessenger.of(context).showSnackBar
                (
                  const SnackBar(content: Text("Coming soon")),
                );
              },
            ),

            const Spacer(),

            buildButton
            (
              text: "Sign Out",
              onPressed: () => signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
