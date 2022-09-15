import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs_clone/colors.dart';
import 'package:google_docs_clone/common/widgets/loader.dart';
import 'package:google_docs_clone/repository/auth_repository.dart';
import 'package:google_docs_clone/repository/document_repository.dart';
import 'package:routemaster/routemaster.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mydocs = ref.watch(myDocumentsProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => createDocument(ref, context),
            icon: const Icon(
              Icons.add,
              color: kBlackColor,
            ),
          ),
          IconButton(
            onPressed: () => signout(ref),
            icon: const Icon(
              Icons.logout,
              color: kRedColor,
            ),
          ),
        ],
      ),
      body: Center(
        child: mydocs.when(
          data: (docs) => docs!.isNotEmpty
              ? Container(
                  width: 800,
                  margin: const EdgeInsets.only(top: 10),
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: ((context, index) {
                      final doc = docs[index];
                      return SizedBox(
                        height: 50,
                        child: InkWell(
                          onTap: () => navigateToDocument(context, doc.id),
                          child: Card(
                            child: Center(
                              child: Text(doc.title),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                )
              : const SizedBox.shrink(),
          error: (error, stackTrace) => Text(error.toString()),
          loading: () => const Loader(),
        ),
      ),
    );
  }

  void navigateToDocument(BuildContext context, String documentId) {
    Routemaster.of(context).push('/document/$documentId');
  }

  void createDocument(WidgetRef ref, BuildContext context) async {
    final navigator = Routemaster.of(context);
    final token = ref.read(userProvider)!.token;
    final snackBar = ScaffoldMessenger.of(context);
    final document = await ref.read(documentRepositoryProvider).createDocument(token);
    document.when(
      (doc) => navigator.push(
        '/document/${doc.id}',
      ),
      (error) => snackBar.showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      ),
    );
  }

  void signout(WidgetRef ref) {
    ref.read(authRepositoryProvider).signOut();
    ref.read(userProvider.notifier).update((state) => null);
  }
}
