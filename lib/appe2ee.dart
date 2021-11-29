import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:webcrypto/webcrypto.dart';

/// This class provides key encryption and decryption functionalities.
/// This class makes use of WebCrypto library for encryption and decryption.
/// This class also create Public Private Key Pair upon booting
/// of the app for the first time on a device.
class AppE2EE {
  static final AppE2EE _singleton = AppE2EE._internal();

  factory AppE2EE() {
    return _singleton;
  }

  AppE2EE._internal();

  /// This holds the private, public key pair
  KeyPair<EcdhPrivateKey, EcdhPublicKey>? keyPair;
  Map<String, dynamic>? publicKeyJwk;
  Map<String, dynamic>? privateKeyJwk;
  Uint8List? derivedBits;
  AesGcmSecretKey? aesGcmSecretKey;
  final Uint8List iv = Uint8List.fromList('Initialization Vector'.codeUnits);

  /// This method checks if the keys are stored in the shared preferences
  /// If so it returns the shared key
  /// Else it generates public, private key pair for the
  /// first time the App being opened on a device.
  /// And it saves the keys to the shared preferences
  /// It also computes the derived bytes using the public private keys.
  Future<void> generateKeysIfNotPresent() async {
    final prefs = await SharedPreferences.getInstance();
    String derivedBitsString = (prefs.getString('derivedBits') ?? '');
    String publicKeyJwkStr = prefs.getString('publicKeyJwk') ?? '';

    if (derivedBitsString.isNotEmpty) {
      derivedBits = Uint8List.fromList(derivedBitsString.codeUnits);
      if (publicKeyJwkStr.isNotEmpty) {
        publicKeyJwk = jsonDecode(publicKeyJwkStr) as Map<String, dynamic>;
      }

      String privateKeyJwkStr = prefs.getString('privateKeyJwk') ?? '';
      if (privateKeyJwkStr.isNotEmpty) {
        privateKeyJwk = jsonDecode(privateKeyJwkStr) as Map<String, dynamic>;
      }
      return;
    } else {
      keyPair = await EcdhPrivateKey.generateKey(EllipticCurve.p256);
      deriveBits();
    }
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

  /// This method computes derivedBits using supplied public key (other user's)
  /// And current (local) user's private key
  Future<void> deriveBitsFromPublicKey(
      Map<String, dynamic> otherPublicKeyJwk) async {
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

  /// this method encrypts and returns the given message
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

    return encryptedString;
  }

  /// this method decrypts and returns the given encryptedMessage
  Future<String> decrypt(String? encryptedMessage) async {
    // 4. Decrypt
    aesGcmSecretKey = await AesGcmSecretKey.importRawKey(derivedBits!);
    List<int> message = Uint8List.fromList(encryptedMessage!.codeUnits);
    Uint8List? decryptdBytes = await aesGcmSecretKey?.decryptBytes(message, iv);
    String decryptdString = String.fromCharCodes(decryptdBytes!);

    return decryptdString;
  }
}
