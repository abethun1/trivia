import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    with SingleTickerProviderStateMixin
{
  final supabase = Supabase.instance.client;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  bool isLogin = true;
  bool loading = false;
  String? formMessage;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  Future<bool> usernameTaken(String username) async
  {
    final normalized = username.trim();
    final existing = await supabase
        .from('user_profiles')
        .select('id')
        .ilike('username', normalized)
        .limit(1);

    return existing.isNotEmpty;
  }

  Future<bool> emailTakenInProfiles(String email) async
  {
    final normalized = email.trim().toLowerCase();
    final existing = await supabase
        .from('user_profiles')
        .select('id')
        .ilike('email', normalized)
        .limit(1);

    return existing.isNotEmpty;
  }

  void setFormMessage(String? message)
  {
    if (!mounted) return;
    setState
    (
      ()
      {
        formMessage = message;
      },
    );
  }
  
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

    _pulseController = AnimationController
    (
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseScale = Tween<double>(begin: 0.90, end: 1.2).animate
    (
      CurvedAnimation
      (
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose()
  {
    _pulseController.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> submit() async 
  {
    setFormMessage(null);

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
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } 
      else 
      {
        final desiredUsername = usernameController.text.trim();
        final desiredEmail = emailController.text.trim().toLowerCase();

        final usernameIsTaken = await usernameTaken(desiredUsername);
        if (usernameIsTaken)
        {
          setFormMessage("Username already taken");
          return;
        }

        bool emailIsTaken = false;
        try
        {
          emailIsTaken = await emailTakenInProfiles(desiredEmail);
        }
        catch (_)
        {
          // If email column does not exist yet, rely on Auth error handling.
        }

        if (emailIsTaken)
        {
          setFormMessage("Email already taken");
          return;
        }

        final res = await supabase.auth.signUp
        (
          email: desiredEmail,
          password: passwordController.text,
        );

        if (res.user != null) 
        {
          await supabase.from('user_profiles').insert
          (
            {
              'id': res.user!.id,
              'username': desiredUsername,
              'email': desiredEmail,
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
    on AuthException catch (e)
    {
      final lower = e.message.toLowerCase();
      if (lower.contains("already registered") ||
          lower.contains("already exists"))
      {
        setFormMessage("Email already taken");
      }
      else
      {
        setFormMessage(e.message);
      }
    }
    on PostgrestException catch (e)
    {
      final lower = e.message.toLowerCase();
      if (lower.contains('username'))
      {
        setFormMessage("Username already taken");
      }
      else if (lower.contains('email'))
      {
        setFormMessage("Email already taken");
      }
      else
      {
        setFormMessage(e.message);
      }
    }
    catch (e) 
    {
      setFormMessage(e.toString());
    }
    finally
    {
      if (mounted)
      {
        setState
        (
          ()
          {
            loading = false;
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold
    (
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/title_screen_background.png",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Center
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
                    //Title Screen, Login/Signup fields, and buttons
                    children: 
                    [
                  AnimatedBuilder
                  (
                    animation: _pulseScale,
                    builder: (_, child)
                    {
                      return Transform.scale
                      (
                        scale: _pulseScale.value,
                        child: child,
                      );
                    },
                    child: Padding
                    (
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox
                      (
                        width: double.infinity,
                        child: AspectRatio
                        (
                          aspectRatio: .9,
                          child: SvgPicture.asset
                          (
                            "assets/images/title_screen.svg",
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

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
                        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w100),
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
                          formMessage = null;
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

                  if (formMessage != null) ...[
                    const SizedBox(height: 10),
                    Text
                    (
                      formMessage!,
                      style: const TextStyle
                      (
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

