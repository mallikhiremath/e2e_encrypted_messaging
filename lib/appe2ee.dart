import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcrypto/webcrypto.dart';

class AppE2EE {
  static final AppE2EE _singleton = AppE2EE._internal();

  factory AppE2EE() {
    return _singleton;
  }

  AppE2EE._internal();

  KeyPair<EcdhPrivateKey, EcdhPublicKey>? keyPair;
  Map<String, dynamic>? publicKeyJwk;
  Map<String, dynamic>? privateKeyJwk;
  Uint8List? derivedBits;
  AesGcmSecretKey? aesGcmSecretKey;
  final Uint8List iv = Uint8List.fromList('Initialization Vector'.codeUnits);

  Future<void> generateKeysIfNotPresent() async {
    final prefs = await SharedPreferences.getInstance();
    String derivedBitsString = (prefs.getString('derivedBits') ?? '');
    String publicKeyJwkStr = prefs.getString('publicKeyJwk') ?? '';
    if (publicKeyJwkStr.isNotEmpty) {
      if (publicKeyJwkStr.isNotEmpty) {
        publicKeyJwk = jsonDecode(publicKeyJwkStr) as Map<String, dynamic>;
      }

      String privateKeyJwkStr = prefs.getString('privateKeyJwk') ?? '';
      if (privateKeyJwkStr.isNotEmpty) {
        privateKeyJwk = jsonDecode(privateKeyJwkStr) as Map<String, dynamic>;
      }

      derivedBits = Uint8List.fromList(derivedBitsString.codeUnits);
      print('derivedBits present');

      return;
    }

    // 1. Generate keys
    keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
    deriveBits();
  }

  Future<void> deriveBits() async {
    // 2. Derive bits
    publicKeyJwk = await keyPair!.publicKey.exportJsonWebKey();
    privateKeyJwk = await keyPair!.privateKey.exportJsonWebKey();

    print('GENERATED keypair $keyPair, $publicKeyJwk, $privateKeyJwk');
    derivedBits = await keyPair!.privateKey.deriveBits(256, keyPair!.publicKey);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('derivedBits', String.fromCharCodes(derivedBits!));
    prefs.setString('publicKeyJwk', jsonEncode(publicKeyJwk));
    prefs.setString('privateKeyJwk', jsonEncode(privateKeyJwk));

    print('derivedBits $derivedBits');
  }

  Future<void> deriveBitsFromPublicKey(
      Map<String, dynamic> otherPublicKeyJwk) async {
    // Map<String, dynamic>? otherPublicKeyJwk;
    // if(otherPublicKeyStr.isNotEmpty) {
    //   otherPublicKeyJwk = jsonDecode(otherPublicKeyStr) as Map<String, dynamic>;
    // }

    final prefs = await SharedPreferences.getInstance();
    String privateKeyJwkStr = prefs.getString('privateKeyJwk') ?? '';
    if (privateKeyJwkStr.isNotEmpty) {
      privateKeyJwk = jsonDecode(privateKeyJwkStr) as Map<String, dynamic>;
      EcdhPrivateKey ecdhPrivateKey = await EcdhPrivateKey.importJsonWebKey(
          privateKeyJwk!, EllipticCurve.p256);
      EcdhPublicKey ecdhPublicKey = await EcdhPublicKey.importJsonWebKey(
          otherPublicKeyJwk!, EllipticCurve.p256);
      derivedBits = await ecdhPrivateKey.deriveBits(256, ecdhPublicKey);
      prefs.setString('derivedBits', String.fromCharCodes(derivedBits!));
      print('DerivedBYTES FROM OTHER PUBLIC KEY $derivedBits');
    }
  }

  Future<String> encrypt(String? message) async {
    // 3. Encrypt
    aesGcmSecretKey = await AesGcmSecretKey.importRawKey(derivedBits!);
    List<int> list = message!.codeUnits;
    Uint8List data = Uint8List.fromList(list);
    Uint8List? encryptedBytes = await aesGcmSecretKey?.encryptBytes(data, iv);
    String? encryptedString;
    if (encryptedBytes != null) {
      encryptedString = String.fromCharCodes(encryptedBytes);
    } else {
      encryptedString = "";
    }

    print('encryptedString $encryptedString');
    return encryptedString;
  }

  Future<String> decrypt(String? encryptedMessage) async {
    // 4. Decrypt
    aesGcmSecretKey = await AesGcmSecretKey.importRawKey(derivedBits!);
    List<int> message = Uint8List.fromList(encryptedMessage!.codeUnits);
    Uint8List? decryptdBytes = await aesGcmSecretKey?.decryptBytes(message, iv);
    String decryptdString = String.fromCharCodes(decryptdBytes!);

    print('decryptdString $decryptdString');
    return decryptdString;
  }
}
