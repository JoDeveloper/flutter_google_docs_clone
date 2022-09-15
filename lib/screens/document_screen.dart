import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs_clone/colors.dart';
import 'package:google_docs_clone/common/widgets/loader.dart';
import 'package:google_docs_clone/models/document_model.dart';
import 'package:google_docs_clone/repository/auth_repository.dart';
import 'package:google_docs_clone/repository/document_repository.dart';
import 'package:google_docs_clone/repository/socket_repository.dart';
import 'package:routemaster/routemaster.dart';

class DocumentScreen extends ConsumerStatefulWidget {
  final String id;
  const DocumentScreen({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  final titleController = TextEditingController(text: 'Untitled Document');
  quill.QuillController? _controller;
  Timer? autoSaveTimer;
  StreamSubscription? _typingSubscription;
  final _socket = SocketRepository();
  DocumentModel? document;

  @override
  void initState() {
    super.initState();

    _socket.joinRoom(widget.id);

    _fetchDocumentData();

    _socket.changeListener(
      (data) => {
        _controller?.compose(quill.Delta.fromJson(data['delta']), _controller?.selection ?? const TextSelection.collapsed(offset: 0), quill.ChangeSource.REMOTE),
      },
    );
    autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _socket.autoSave({
        'delta': _controller?.document.toDelta(),
        'room': widget.id,
      });
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    _controller?.dispose();
    autoSaveTimer?.cancel();
    _typingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Loader());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kWhiteColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'http://localhost:3000/#/document/${widget.id}')).then(
                  (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Link copied!',
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.lock,
                size: 16,
              ),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlueColor,
              ),
            ),
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Routemaster.of(context).replace('/');
                },
                child: Image.asset(
                  'assets/images/docs-logo.png',
                  height: 40,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: kBlueColor,
                      ),
                    ),
                    contentPadding: EdgeInsets.only(left: 10),
                  ),
                  onSubmitted: (value) => updateTitle(ref, value),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: kGreyColor,
                width: 0.1,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            quill.QuillToolbar.basic(controller: _controller!),
            const SizedBox(height: 10),
            Expanded(
              child: SizedBox(
                width: 750,
                child: Card(
                  color: kWhiteColor,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: quill.QuillEditor.basic(
                      controller: _controller!,
                      readOnly: false,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void updateTitle(WidgetRef ref, String title) {
    ref.read(documentRepositoryProvider).updateDocumentTitle(
          token: ref.read(userProvider)!.token,
          documentId: widget.id,
          documentTitle: title,
        );
  }

  void _fetchDocumentData() async {
    final result = await ref.read(documentRepositoryProvider).getDocumentById(
          ref.read(userProvider)!.token,
          widget.id,
        );
    result.when(
      (documentData) {
        document = documentData;
        titleController.text = document!.title;
        _controller = quill.QuillController(
            document: documentData.content.isEmpty
                ? quill.Document()
                : quill.Document.fromDelta(
                    quill.Delta.fromJson(documentData.content),
                  ),
            selection: const TextSelection.collapsed(offset: 0));
        setState(() {});
      },
      (error) => log(error),
    );
    _typingSubscription = _controller!.document.changes.listen((event) {
      if (event.item3 == quill.ChangeSource.LOCAL) {
        final data = {
          'delta': event.item2,
          'room': widget.id,
        };
        _socket.typing(data);
      }
    });
  }
}
