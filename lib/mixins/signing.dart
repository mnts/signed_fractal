import '../signed_fractal.dart';

mixin SigningMix on NodeFractal {
  static const attributes = [
    Attr(
      'private_key',
      String,
      isPrivate: true,
    ),
    Attr(
      'public_key',
      String,
    ),
  ];

  static final map = <String, SigningMix>{};

  late KeyPair keyPair;
  _construct() {
    //map[keyPair.privateKey] = this;
  }

  signing() {
    keyPair = RandomKeyPairGenerator().generate();
    _construct();
  }

  signingFromMap(MP d) {
    keyPair = d['public_key'] != null
        ? KeyPair(
            publicKey: d['public_key'],
            privateKey: d['private_key'],
          )
        : RandomKeyPairGenerator().generate();
    _construct();
  }

  MP get signingMap => {
        'public_key': keyPair.publicKey,
        'private_key': keyPair.privateKey,
      };

  static final signer = Signer();
  String sign(String text) => signer.sign(
        privateKey: keyPair.privateKey,
        message: text,
      );
}
