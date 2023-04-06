import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _singleton = SecureStorage._internal();
  final FlutterSecureStorage _storage =  const FlutterSecureStorage();

  factory SecureStorage() {
    return _singleton;
  }

  SecureStorage._internal();

  FlutterSecureStorage get storage {
    return _storage;
  }
}