import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:fractal/types/file.dart';
import 'package:signed_fractal/models/rewriter.dart';
import 'package:signed_fractal/signed_fractal.dart';

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

  String? name;
  String? eth;
  String? pass;

  UserFractal({
    required this.name,
    this.eth,
    super.expiresAt,
    super.kind,
    super.content,
    super.file,
    super.to,
    super.keyPair,
    String? password,
  }) {
    if (password != null) {
      pass = makePass(password);
    }
  }

  String makePass(String word) {
    final b = md5.convert(utf8.encode(word)).bytes;

    return bs58check.encode(
      Uint8List.fromList(b),
    );
  }

  static activate(UserFractal user) {
    UserFractal.active.value = user;
    DBF.main['active'] = user.hash;
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
      controller.map.values.firstWhere((u) => u.eth == address);

  @override
  get hashData => [
        ...super.hashData,
      ];

  static late final activeHash = DBF.main['active'];

  UserFractal.fromMap(MP d)
      : name = d['name'],
        eth = d['eth'],
        pass = d['pass'],
        super.fromMap(d) {
    if (activeHash != null && activeHash == hash) active.value = this;
  }

  MP get _map => {
        'eth': eth,
        'name': name,
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
