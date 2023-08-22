import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

import '../codec/private_key_codec.dart';
import '../codec/public_key_codec.dart';
import '../key_pair.dart';
import 'key_pair_generator.dart';

/// A key pair generator that generates random key pairs.
class RandomKeyPairGenerator implements KeyPairGenerator<dynamic> {
  const RandomKeyPairGenerator();

  @override
  KeyPair generate({dynamic params}) {
    final domainParams = ECCurve_secp256k1();
    final keyGeneratorParams = ECKeyGeneratorParameters(domainParams);
    final random = _createSecureRandom();
    final cipherParams = ParametersWithRandom(keyGeneratorParams, random);
    final generator = ECKeyGenerator();
    generator.init(cipherParams);
    final ecKeyPair = generator.generateKeyPair();
    final ecPublicKey = ecKeyPair.publicKey as ECPublicKey;
    final ecPrivateKey = ecKeyPair.privateKey as ECPrivateKey;
    return KeyPair(
      publicKey: const PublicKeyCodec().encode(ecPublicKey),
      privateKey: const PrivateKeyCodec().encode(ecPrivateKey),
    );
  }

  SecureRandom _createSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    final keyParams = KeyParameter(Uint8List.fromList(seeds));
    secureRandom.seed(keyParams);
    return secureRandom;
  }
}
