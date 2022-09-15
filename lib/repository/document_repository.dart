import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs_clone/constants.dart';
import 'package:google_docs_clone/models/document_model.dart';
import 'package:google_docs_clone/models/result_modal.dart';
import 'package:google_docs_clone/repository/auth_repository.dart';
import 'package:http/http.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(client: Client());
});

final myDocumentsProvider = FutureProvider<List<DocumentModel>?>((ref) async {
  final docsProvider = ref.read(documentRepositoryProvider);
  final token = ref.read(userProvider)!.token;
  final result = await docsProvider.getMyDocuments(token);
  if (result.isSuccess()) {
    return result.getSuccess() ?? [];
  }
  return [];
});

class DocumentRepository {
  final Client _client;

  DocumentRepository({
    required Client client,
  }) : _client = client;

  Future<Result<DocumentModel, String>> getDocumentById(String token, String documentId) async {
    try {
      final response = await _client.get(
        Uri.parse('$host/docs/$documentId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      log(response.body, name: 'getDocumentById');

      switch (response.statusCode) {
        case HttpStatus.ok:
          return Success(DocumentModel.fromMap(json.decode(response.body)['doc']));
        case HttpStatus.internalServerError:
        case HttpStatus.badRequest:
        default:
          return Error(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Result<DocumentModel, String>> createDocument(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('$host/docs/create'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      log(response.body);

      switch (response.statusCode) {
        case HttpStatus.ok:
          return Success(DocumentModel.fromJson(response.body));
        case HttpStatus.internalServerError:
        case HttpStatus.badRequest:
        default:
          return Error(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Result<String, String>> updateDocumentTitle({
    required String token,
    required String documentTitle,
    required String documentId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$host/docs/change-title'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'id': documentId,
          'title': documentTitle,
        }),
      );

      log(response.body);

      switch (response.statusCode) {
        case HttpStatus.ok:
          return Success(jsonDecode(response.body)['success']);
        case HttpStatus.internalServerError:
        case HttpStatus.badRequest:
        default:
          return Error(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }

  Future<Result<List<DocumentModel>, String>> getMyDocuments(String token) async {
    try {
      final response = await _client.get(Uri.parse('$host/docs/me'), headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      });

      switch (response.statusCode) {
        case HttpStatus.ok:
          final docs = (jsonDecode(response.body)['docs'] as List)
              .map(
                (doc) => DocumentModel.fromMap(doc),
              )
              .toList();
          return Success(docs);
        case HttpStatus.internalServerError:
        case HttpStatus.badRequest:
        default:
          return Error(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      return Error(e.toString());
    }
  }
}
