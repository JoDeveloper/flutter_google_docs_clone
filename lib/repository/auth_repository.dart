import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_docs_clone/constants.dart';
import 'package:google_docs_clone/models/result_modal.dart';
import 'package:google_docs_clone/models/user_model.dart';
import 'package:google_docs_clone/repository/local_storage_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    googleSignIn: GoogleSignIn(),
    client: Client(),
    localStorage: LocalStorageRepository(),
  );
});

final userProvider = StateProvider<UserModel?>((ref) => null);

class AuthRepository {
  final GoogleSignIn _googleSignIn;
  final Client _client;
  final LocalStorageRepository _localStorage;

  AuthRepository({
    required GoogleSignIn googleSignIn,
    required Client client,
    required LocalStorageRepository localStorage,
  })  : _googleSignIn = googleSignIn,
        _client = client,
        _localStorage = localStorage;

  Future<Result<UserModel, String>> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final userAccount = await _googleSignIn.signIn();
      if (userAccount != null) {
        final user = UserModel(
          email: userAccount.email,
          name: userAccount.displayName ?? '',
          profilePic: userAccount.photoUrl ?? '',
          uid: '',
          token: '',
        );

        final response = await _client.post(
          Uri.parse('$host/api/signup'),
          body: user.toJson(),
          headers: {'Content-Type': 'application/json'},
        );
        switch (response.statusCode) {
          case HttpStatus.ok:
            final newUser = user.copyWith(
              uid: jsonDecode(response.body)['user']['_id'],
              token: jsonDecode(response.body)['token'],
            );
            _localStorage.setToken(newUser.token);
            return Success(newUser);
          case HttpStatus.internalServerError:
          case HttpStatus.badRequest:
          default:
            return Error(jsonDecode(response.body)['error']);
        }
      }
    } catch (e) {
      return Error(e.toString());
    }

    throw Exception;
  }

  Future<Result<UserModel, String>> getUserData() async {
    try {
      final token = await _localStorage.getToken();
      if (token == null) return const Error('null token');

      final response = await _client.get(
        Uri.parse('$host/api/getUserdata'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      switch (response.statusCode) {
        case HttpStatus.ok:
          final user = UserModel.fromMap({
            ...jsonDecode(response.body)['user'],
            ...{'token': token},
          });
          _localStorage.setToken(user.token);
          return Success(user);
        case HttpStatus.internalServerError:
        case HttpStatus.badRequest:
          return Error(jsonDecode(response.body)['error']);
        default:
      }
    } catch (e) {
      return Error(e.toString());
    }
    return const Error('Error occurred');
  }

  void signOut() async {
    _localStorage.setToken('');
    await _googleSignIn.signOut();
  }
}
