import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:unimec/model/secureStorage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../utils/cryptoHandle.dart';

class HealthRecordProcessor {
  DocumentSnapshot<Object?> data;
  final String userUID;
  final String password;
  String previousHash = "";
  Tuple2<Map<String, dynamic>, Map<String, dynamic>> processedData = const Tuple2(
      {}, {});

  HealthRecordProcessor(this.data, this.userUID, this.password);

  void getHealthRecord() {
    late Map<String, dynamic> mapData;
    try {
      mapData = data.data()! as Map<String, dynamic>;
    }
    catch (exception) {
      if (kDebugMode) {
        print("Exception met");
        print(exception);
        return;
      }
    }

    if (!mapData.containsKey("public")) {
      return;
    }
    
    if (!mapData.containsKey("private")) {
      return;
    }

    processedData = Tuple2(mapData["public"], processedData.item2);
    if (previousHash == mapData["private"]) {
      return;
    }

    // backup hash
    previousHash = mapData["private"];

    var privateData = parseEncryptedData(mapData["private"], userUID, password);
    privateData.then((value) {
      processedData = Tuple2(mapData["public"], value);
    });
    return ;
  }

  Future<dynamic> getHealthRecordDataByKey(key) async {
    while(processedData.item2.keys.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (processedData.item1.containsKey(key)) {
      return processedData.item1[key];
    }
    while(processedData.item2.keys.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
    }
    if (processedData.item2.containsKey(key)) {
      return processedData.item2[key];
    }
    return "";
  }

  // return a base64 encoded of cbc encrypted data
  Future<String> createEncryptedData(Map<String, dynamic> secretData, String userUID, String password) async {
    final storage = SecureStorage().storage;
    final readUserStoredData = await storage.read(key: userUID);
    if (readUserStoredData == null || readUserStoredData.isEmpty) {
      return "";
    }
    final parsedUserStoredData = json.decode(utf8.decode(base64.decode(readUserStoredData!)));

    // Create an encryption key from the password
    final genEncryptedKey = generateKeyFromPassword(password, utf8.decode(base64.decode(parsedUserStoredData["salt"])), parsedUserStoredData["iteration"], parsedUserStoredData["key_length"]);
    final encryptedKeyBase64 = base64.encode(genEncryptedKey);
    final encryptKey = encrypt.Key.fromBase64(encryptedKeyBase64);
    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey, mode: encrypt.AESMode.cbc));

    // encrypt secret data
    final encodedData = base64.encode(utf8.encode(json.encode(secretData)));
    final encrypted = encrypter.encrypt(encodedData, iv: encrypt.IV(base64.decode(parsedUserStoredData["iv"])));

    // return base64 encoded
    return encrypted.base64;
  }

  // return secret data
  Future<Map<String, dynamic>> parseEncryptedData(String encryptedData, String userUID, String password) async {
    final storage = SecureStorage().storage;
    final readUserStoredData = await storage.read(key: userUID);
    final parsedUserStoredData = json.decode(utf8.decode(base64.decode(readUserStoredData!)));

    // Create a new AES CBC decryption cipher with the key and IV
    final genDecryptedKey = generateKeyFromPassword(password, utf8.decode(base64.decode(parsedUserStoredData["salt"])), parsedUserStoredData["iteration"], parsedUserStoredData["key_length"]);
    final decryptedKeyBase64 = base64.encode(genDecryptedKey);
    final decryptKey = encrypt.Key.fromBase64(decryptedKeyBase64);
    final decrypter = encrypt.Encrypter(encrypt.AES(decryptKey, mode: encrypt.AESMode.cbc));

    // decrypt secret data
    final decrypted = decrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedData), iv: encrypt.IV(base64.decode(parsedUserStoredData["iv"])));
    return json.decode(utf8.decode(base64.decode(decrypted)));
  }
}
