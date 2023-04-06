import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';


Uint8List generateKeyFromPassword(String password, String salt, int iterationCount, int keyLength) {
  const utf8 = Utf8Encoder();
  final passwordBytes = utf8.convert(password);
  final saltBytes = utf8.convert(salt);

  final mac = HMac(SHA256Digest(), 64);
  final pbkdf2 = PBKDF2KeyDerivator(mac)..init(Pbkdf2Parameters(saltBytes, iterationCount, keyLength ~/ 8));

  final keyBytes = pbkdf2.process(passwordBytes);
  return keyBytes;
}

String generateSalt(int length) {
  final random = Random.secure();
  final saltBytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    saltBytes[i] = random.nextInt(256);
  }
  return base64.encode(saltBytes);
}