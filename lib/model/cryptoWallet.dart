import 'package:flutter/foundation.dart';

class CryptoWallet {
  final String seedPhrase;
  final String privateKey;
  final String address;
  
  CryptoWallet(this.seedPhrase, this.privateKey, this.address);
  
  debugLog() {
    if (kDebugMode) {
      print("------ DEBUG LOG ------");
      print('Seed phrase: $seedPhrase');
      print('Private key: $privateKey');
      print('Wallet address: $address');
    }
  }
}