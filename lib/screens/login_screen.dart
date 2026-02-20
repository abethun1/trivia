import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_screen.dart';
import 'loading_screen.dart';
import '../styles/login_styles.dart';

class LoginScreen extends StatefulWidget 
{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState()
  {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> 
{
  final supabase = Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  
  bool canSubmit()
  {
    if (isLogin)
    {
      return emailController.text.isNotEmpty &&
             passwordController.text.isNotEmpty;
    }
    else
    {
      return usernameController.text.isNotEmpty &&
             emailController.text.isNotEmpty &&
             passwordController.text.isNotEmpty;
    }
  }

  @override
  void initState()
  {
    super.initState();

    emailController.addListener(() => setState(() {}));
    passwordController.addListener(() => setState(() {}));
    usernameController.addListener(() => setState(() {}));
  }

  @override
  void dispose()
  {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> submit() async 
  {
    setState
    (
      ()
      {
        loading = true;
      },
    );

    try 
    {
      if (isLogin) 
      {
        await supabase.auth.signInWithPassword
        (
          email: emailController.text,
          password: passwordController.text,
        );
      } 
      else 
      {
        final res = await supabase.auth.signUp
        (
          email: emailController.text,
          password: passwordController.text,
        );

        if (res.user != null) 
        {
          await supabase.from('user_profiles').insert
          (
            {
              'id': res.user!.id,
              'username': usernameController.text,
            },
          );
        }
      }

      if (!mounted) 
      {
        return;
      }

      Navigator.pushReplacement
      (
        context,
        MaterialPageRoute
        (
          builder: (_) => const LoadingScreen(),
        ),
      );
    } 
    catch (e) 
    {
      ScaffoldMessenger.of(context).showSnackBar
      (
        SnackBar
        (
          content: Text(e.toString()),
        ),
      );
    }

    setState
    (
      ()
      {
        loading = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      body: Center
      (
        child: SingleChildScrollView
        (
          child: Padding
          (
            padding: const EdgeInsets.all(24),
            child: Container
            (
              padding: const EdgeInsets.all(24),
              constraints: LoginStyles.cardConstraints,
              child: Column
              (
                mainAxisSize: MainAxisSize.min,
                children: 
                [
                  const Text
                  (
                    "What do you know?\nDo you know things?\nLet’s find out!",
                    textAlign: TextAlign.center,
                    style: LoginStyles.headerText,
                  ),

                  const SizedBox(height: 32),

                  if (!isLogin)
                    Container
                    (
                      decoration: LoginStyles.fieldContainerDecoration,
                      child: TextField
                      (
                        controller: usernameController,
                        decoration: LoginStyles.inputDecoration("Username"),
                      )
                    ),

                  if (!isLogin)
                    const SizedBox(height: 12),

                  Container
                  (
                    decoration: LoginStyles.fieldContainerDecoration,
                    child: TextField
                    (
                      controller: emailController,
                      decoration: LoginStyles.inputDecoration("Email"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container
                  (
                    decoration: LoginStyles.fieldContainerDecoration,
                    child: TextField
                    (
                      controller: passwordController,
                      obscureText: true,
                      decoration: LoginStyles.inputDecoration("Password"),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox
                  (
                    width: double.infinity,
                    child: ElevatedButton
                    (
                      onPressed: loading || !canSubmit() ? null : submit,
                      style: LoginStyles.mainButtonStyle,
                      child: Text
                      (
                        loading
                          ? "Loading..."
                          : isLogin
                              ? "Login"
                              : "Sign Up",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton
                  (
                    onPressed: ()
                    {
                      setState
                      (
                        ()
                        {
                          isLogin = !isLogin;
                        },
                      );
                    },
                    child: Text
                    (
                      isLogin
                        ? "Don’t have an account? Sign up"
                        : "Already have an account? Login",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
