import 'package:flutter/foundation.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';

class CryptoWallet {
  late final String seedPhrase;
  late final String privateKey;
  late final String address;
  
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

CryptoWallet getNewWallet() {
  // Generate a new BIP-39 mnemonic seed phrase
  final mnemonic = bip39.generateMnemonic();

  // Derive an Ethereum HD wallet from the seed phrase
  final seed = bip39.mnemonicToSeed(mnemonic);
  final root = bip32.BIP32.fromSeed(seed);

  // Derive the first Ethereum private key from the HD wallet
  final child = root.derivePath("m/44'/60'/0'/0/0");
  final privateKey = EthPrivateKey.fromHex('0x${hex.encode(child.privateKey?.toList() ?? [])}');

  // Convert the private key to a list of bytes
  final privateKeyBytes = privateKey.privateKey.toList();

  // Convert the private key to a hexadecimal string
  final privateKeyHex = '0x${hex.encode(privateKeyBytes)}';

  // Get the Ethereum address from the private key
  final address = privateKey.address.hex;

  return CryptoWallet(mnemonic, privateKeyHex, address);
}