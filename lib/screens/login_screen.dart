import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatelessWidget {

  const LoginScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final auth =
        context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JournalAI Login',
        ),
      ),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.school,
                size: 100,
                color: Colors.blue,
              ),

              const SizedBox(height: 20),

              const Text(
                'Welcome to JournalAI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton.icon(

                icon: const Icon(
                  Icons.login,
                ),

                label: const Text(
                  'Sign in with Google',
                ),

                onPressed:
                    auth.isLoading
                        ? null
                        : () async {

                            await auth
                                .signInWithGoogle();
                          },
              ),

              const SizedBox(height: 20),

              if (auth.isLoading)
                const CircularProgressIndicator(),

              if (auth.errorMessage != null)
                Text(
                  auth.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}