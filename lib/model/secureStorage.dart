import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../utils/cryptoHandle.dart';
import 'cryptoWallet.dart';

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

  // store the seed phrase & private key into secure storage
  Future<void> storeWallet(String userUID, String password, CryptoWallet wallet) async {
    // TODO: store salt in decentralized server
    // Create an encryption key from the password
    const keyLength = 256; // Key length in bits (can be 128, 192, or 256)
    final salt = generateSalt(keyLength);
    const iterationCount = 10000; // Choose a suitable iteration count (e.g. between 10000 and 100000)
    final key = generateKeyFromPassword(password, salt, iterationCount, keyLength);

    // Generate a random initialization vector (IV)
    final iv = encrypt.IV.fromLength(16);

    // Create a new AES CBC encryption cipher with the key and IV
    final keyBase64 = base64.encode(key);
    final encryptKey = encrypt.Key.fromBase64(keyBase64);
    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey, mode: encrypt.AESMode.cbc));

    final userData = {
      "seed_phrase": wallet.seedPhrase,
      "private_key": wallet.privateKey,
      "address": wallet.address,
    };

    // Encrypt the plaintext using the cipher and IV
    final encodedData = base64.encode(utf8.encode(json.encode(userData)));
    final encrypted = encrypter.encrypt(encodedData, iv: iv);

    final userStoredData = {
      "private": encrypted.base64,
      "iv": iv.base64,
      "salt": base64.encode(utf8.encode(salt)),
      "key_length": keyLength,
      "iteration": iterationCount,
    };

    await _storage.write(key: userUID, value: base64.encode(utf8.encode(json.encode(userStoredData))));
  }

  Future<CryptoWallet> retrieveWallet(String userUID, String password) async {
    final readUserStoredData = await _storage.read(key: userUID);
    final parsedUserStoredData = json.decode(utf8.decode(base64.decode(readUserStoredData!)));

    // Create a new AES CBC decryption cipher with the key and IV
    final genDecryptedKey = generateKeyFromPassword(password, utf8.decode(base64.decode(parsedUserStoredData["salt"])), parsedUserStoredData["iteration"], parsedUserStoredData["key_length"]);
    final decryptedKeyBase64 = base64.encode(genDecryptedKey);
    final decryptKey = encrypt.Key.fromBase64(decryptedKeyBase64);
    final decrypter = encrypt.Encrypter(encrypt.AES(decryptKey, mode: encrypt.AESMode.cbc));

    final decrypted = decrypter.decrypt(encrypt.Encrypted.fromBase64(parsedUserStoredData["private"]), iv: encrypt.IV(base64.decode(parsedUserStoredData["iv"])));
    final parsedUserSecretData = json.decode(utf8.decode(base64.decode(decrypted)));

    return CryptoWallet(parsedUserSecretData["seed_phrase"], parsedUserSecretData["private_key"], parsedUserSecretData["address"]);
  }
}