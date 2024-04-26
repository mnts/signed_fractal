import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:fractal_socket/index.dart';
import '../signed_fractal.dart';
import 'package:collection/collection.dart';

class UserCtrl<T extends UserFractal> extends NodeCtrl<T> {
  UserCtrl({
    super.name = 'user',
    required super.make,
    required super.extend,
    required super.attributes,
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
    attributes: [
      Attr(
        name: 'eth',
        format: 'TEXT',
        canNull: true,
      ),
      Attr(
        name: 'pass',
        format: 'TEXT',
      ),
      ...SigningMix.attributes,
    ],
  );

  static Future init() async {
    await controller.init();
    if (activeHash != null) {
      CatalogFractal(
        filter: {
          'event': {'hash': activeHash},
        },
        source: UserFractal.controller,
      );
    }
  }

  @override
  UserCtrl get ctrl => controller;

  @override
  String get path => '/@$name';

  String? eth;
  String? pass;

  static final flow = TypeFilter<UserFractal>(NodeFractal.flow);

  static FutureOr<UserFractal?> byName(String name) async {
    final user = flow.list.firstWhereOrNull(
      (f) => f.name == name,
    );

    if (user == null) {
      ClientFractal.main?.sink({
        'cmd': 'search',
        'type': UserFractal.controller.name,
        'where': {'name': name},
      });
    }

    return user;
  }

  late final KeyPair keyPair;

  @override
  UserFractal({
    this.eth,
    super.to,
    super.keyPair,
    super.extend,
    String? password,
    required super.name,
  }) : keyPair = SigningMix.signing() {
    if (password != null) {
      pass = makePass(password);
    }
    //map.complete(name, this);
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

  static final activeHash = DBF.main['active'];

  UserFractal.fromMap(MP d)
      : eth = d['eth'],
        pass = d['pass'],
        keyPair = SigningMix.signingFromMap(d),
        super.fromMap(d) {
    if (d['password'] case String password) {
      pass = makePass(password);
    }

    if (activeHash != null && activeHash == hash) active.value = this;

    //map.complete(name, this);
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

  @override
  Object? operator [](String key) => switch (key) {
        'eth' => eth,
        _ => super[key],
      };
}
