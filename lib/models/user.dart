import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:signed_fractal/signed_fractal.dart';
import '../security/generator/random_key_pair_generator.dart';
import '../security/key_pair.dart';

class UserFractal extends NodeFractal implements Rewritable {
  static final active = Frac<UserFractal?>(null);

  static final controller = UserCtrl(
    make: (d) => switch (d) {
      MP() => UserFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
    extend: NodeFractal.controller,
  );

  @override
  UserCtrl get ctrl => controller;

  @override
  String get path => '/~$name';

  String? eth;
  String? pass;

  static final map = MapF<UserFractal>();

  late final KeyPair keyPair;

  @override
  String get pubkey => keyPair.publicKey;

  UserFractal({
    this.eth,
    super.to,
    super.keyPair,
    String? password,
    required super.name,
  }) {
    keyPair = RandomKeyPairGenerator().generate();

    if (password != null) {
      pass = makePass(password);
    }
    map.complete(name, this);
  }

  String makePass(String word) {
    final b = md5.convert(utf8.encode(word)).bytes;

    return bs58check.encode(
      Uint8List.fromList(b),
    );
  }

  static final signer = Signer();
  String sign(String text) => signer.sign(
        privateKey: keyPair.privateKey,
        message: text,
      );

  static activate(UserFractal user) {
    UserFractal.active.value = user;
    DBF.main['active'] = user.hash;
  }

  static logOut() {
    UserFractal.active.value = null;
    DBF.main['active'] = '';
  }

  bool auth(String password) {
    return makePass(password) == pass;
    /*
    if (pass == null || pass!.length != 32) return false;

    final h = makePass(password);

    /*
    for (var i = 0; i < h.length; i++) {
      if (h[i] != pass![i]) return false;
    }
    */

    return true;
    */
  }

  static UserFractal byEth(String address) =>
      map.values.firstWhere((u) => u.eth == address);

  @override
  get hashData => [
        ...super.hashData,
      ];

  static late final activeHash = DBF.main['active'];

  UserFractal.fromMap(MP d)
      : eth = d['eth'],
        pass = d['pass'],
        keyPair = KeyPair(
          publicKey: d['public_key'],
          privateKey: d['private_key'],
        ),
        super.fromMap(d) {
    if (activeHash != null && activeHash == hash) active.value = this;

    map.complete(name, this);
  }

  MP get _map => {
        'eth': eth,
        'public_key': keyPair.publicKey,
        'private_key': keyPair.privateKey,
        'pass': pass ?? '',
      };

  synch() {
    super.synch();
  }

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };
}
