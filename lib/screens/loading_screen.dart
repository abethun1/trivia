import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_screen.dart';
import '../models/user_profile.dart';
import '../widgets/app_background.dart';

class LoadingScreen extends StatefulWidget
{
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState()
  {
    return _LoadingScreenState();
  }
}

class _LoadingScreenState extends State<LoadingScreen>
{
  final supabase = Supabase.instance.client;

  UserProfile? userProfile;

  @override
  void initState()
  {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async
  {
    final user = supabase.auth.currentUser;

    if (user == null)
    {
      return;
    }

    final data = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .single();

    userProfile = UserProfile.fromMap(data);

    if (!mounted)
    {
      return;
    }

    Navigator.pushReplacement
    (
      context,
      MaterialPageRoute
      (
        builder: (_) => DashboardScreen(userProfile: userProfile!),
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      body: AppBackground(
        child: Center
        (
          child: Column
          (
            mainAxisAlignment: MainAxisAlignment.center,
            children:
            [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text("Loading your profile..."),
            ],
          ),
        ),
      ),
    );
  }
}
