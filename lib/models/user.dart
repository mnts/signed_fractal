import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_bs58check/dart_bs58check.dart';
import '../signed_fractal.dart';

class UserCtrl<T extends UserFractal> extends NodeCtrl<T> {
  UserCtrl({
    super.name = 'user',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr(
        'eth',
        String,
        canNull: true,
      ),
      Attr(
        'pass',
        String,
      ),
      ...SigningMix.attributes,
    ],
  });

  @override
  final icon = IconF(0xe491);
}

class UserFractal extends NodeFractal with SigningMix {
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
  String get path => '/@$name';

  String? eth;
  String? pass;

  static final map = MapF<UserFractal>();

  late final KeyPair keyPair;

  @override
  UserFractal({
    this.eth,
    super.to,
    super.keyPair,
    super.extend,
    String? password,
    required super.name,
  }) {
    signing();

    if (password != null) {
      pass = makePass(password);
    }
    map.complete(name, this);
  }

  static String makePass(String word) {
    final b = md5.convert(utf8.encode(word)).bytes;

    return bs58check.encode(
      Uint8List.fromList(b),
    );
  }

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
        super.fromMap(d) {
    signingFromMap(d);
    if (d['password'] case String password) {
      pass = makePass(password);
    }

    if (activeHash != null && activeHash == hash) active.value = this;

    map.complete(name, this);
  }

  MP get _map => {
        ...signingMap,
        'eth': eth,
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
