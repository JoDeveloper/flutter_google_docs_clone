import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs_clone/colors.dart';
import 'package:google_docs_clone/repository/auth_repository.dart';
import 'package:routemaster/routemaster.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  void signInwithGoogle(WidgetRef ref, BuildContext context) async {
    final scaffoldMesg = ScaffoldMessenger.of(context);
    final navigator = Routemaster.of(context);

    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    result.when(
      (user) {
        ref.read(userProvider.notifier).update((state) => user);
        navigator.replace('/');
      },
      (error) => scaffoldMesg.showSnackBar(
        SnackBar(content: Text(error)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => signInwithGoogle(ref, context),
          icon: Image.asset(
            'assets/images/g-logo-2.png',
            height: 20,
          ),
          label: const Text(
            'Sign in with Google',
            style: TextStyle(
              color: kBlackColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kWhiteColor,
            minimumSize: const Size(150, 50),
          ),
        ),
      ),
    );
  }
}
