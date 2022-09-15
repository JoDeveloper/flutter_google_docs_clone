import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs_clone/repository/auth_repository.dart';
import 'package:google_docs_clone/routes.dart';
import 'package:routemaster/routemaster.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    _getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routeInformationParser: const RoutemasterParser(),
      routerDelegate: RoutemasterDelegate(routesBuilder: (_) {
        final user = ref.watch(userProvider);
        log(user.toString(), name: 'routerDelegate');
        if (user != null && user.token.isNotEmpty) {
          return loggedInRoute;
        }
        return loggedOutRoute;
      }),
    );
  }

  void _getUserData() async {
    final result = await ref.read(authRepositoryProvider).getUserData();
    result.when(
      (user) => ref.read(userProvider.notifier).update((state) => user),
      (error) => null,
    );
  }
}
