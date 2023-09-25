import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:fractal/lib.dart';
import 'package:fractal/types/file.dart';
import '../controllers/events.dart';
import 'package:convert/convert.dart';
import 'package:dart_bs58check/dart_bs58check.dart';

import '../security/key_pair.dart';
import '../services/map.dart';
import 'user.dart';

class EventFractal extends Fractal {
  static final controller = EventsCtrl(
    extend: Fractal.controller,
    make: (d) => switch (d) {
      MP() => EventFractal.fromMap(d),
      null || Object() => throw ('wrong event type')
    },
  );

  static final map = MapF();

  @override
  EventsCtrl get ctrl => controller;

  bool get dontStore => false;

  String hash = '';
  late final String pubkey;
  int createdAt = 0;
  final int syncAt;
  final int expiresAt;
  final int kind;
  final String content;
  String sig = '';
  FileF? file;

  signa() {
    if (hash.isEmpty) {
      throw Exception(
        'event is not complete for signature',
      );
    }
  }

  //static late final user = UserNostr();

  //final tags = <List<String>>[];
  List get hashData => [0, pubkey, createdAt, type, content, ctrl.name];

  makeHash() {
    String serializedEvent = json.encode(hashData);
    final h = Uint8List.fromList([
      kind,
      ...sha256.convert(utf8.encode(serializedEvent)).bytes,
    ]);
    return bs58check.encode(h);
  }

  move() {}

  EventFractal? to;

  EventFractal({
    super.id,
    this.hash = '',
    String? pubkey,
    int createdAt = 0,
    this.syncAt = 0,
    this.expiresAt = 0,
    this.kind = 1,
    this.owner,
    this.content = '',
    this.file,
    this.sig = '',
    this.to,
  }) {
    this.pubkey = pubkey ?? _myKeyPair?.publicKey ?? '';
    if (createdAt == 0) this.createdAt = unixSeconds;
    owner = UserFractal.active.value;
    if (to != null) {
      toHash = to!.hash;
      _consume(to!);
    }

    ownerC.complete();
  }

  KeyPair? get _myKeyPair => UserFractal.active.value?.keyPair;
  bool get own => _myKeyPair != null && pubkey == _myKeyPair!.publicKey;

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };

  UserFractal? owner;

  final ownerC = Completer();

  MP get _map => {
        'hash': hash,
        'pubkey': pubkey,
        'owner': owner?.hash ?? UserFractal.active.value?.hash,
        'created_at': createdAt,
        'sync_at': syncAt,
        'expires_at': expiresAt,
        'kind': kind,
        'content': content,
        'file': file?.name ?? '',
        'sig': sig,
        'pid': sig,
        'to': to?.hash ?? toHash ?? '',
      };

  String? toHash;

  EventFractal.fromMap(MP d)
      : hash = d['hash'] ?? '',
        pubkey = d['pubkey'] ?? '',
        content = d['content'] ?? '',
        createdAt = d['created_at'] ?? 0,
        syncAt = d['sync_at'] ?? 0,
        expiresAt = d['expires_at'] ?? 0,
        sig = d['sig'] ?? '',
        kind = 1,
        super(id: d['id']) {
    if (d case {'file': String fileHash}) {
      if (fileHash.isNotEmpty) file = FileF(fileHash);
    }

    if (d case {'owner': String userHash}) {
      if (userHash.isNotEmpty) {
        map.request(userHash).then((user) {
          if (user is UserFractal) {
            owner = user;
            ownerC.complete();
          }
        });
      }
    }

    if (d case {'to': String toHash}) {
      this.toHash = toHash;
      map.request(toHash).then(_consume);
    }
    complete();
  }

  static final listeners = <String, Function(EventFractal)>{};
  static listen(String name, Function(EventFractal) cb) {
    listeners[name] = (cb);
  }

  static unListen(String name) {
    listeners.remove(name);
  }

  factory EventFractal.make(Map<String, dynamic> m) {
    //relay.isConnected ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : 0;
    int expires = m.remove('_expiresAfter') ?? 0;

    return EventFractal(
      content: m['content'],
      expiresAt: (expires > 0) ? (unixSeconds + expires) : 0,
    );
  }

  _consume(EventFractal into) {
    to = into;

    provide(into);
    into.consume(this);
  }

  consume(EventFractal event) {
    /*
    print('consume');
    print(event);
    */
  }

  provide(EventFractal into) {
    /*
    print('provide');
    print(into);
    */
  }

  String get url => hash;

  int idEvent = 0;
  @override
  synch() {
    if (map.containsKey(hash)) {
      distribute();
      return 0;
    }
    complete();
    distribute();
    super.synch();
  }

  distribute() {
    for (var entry in listeners.entries) {
      if (sharedWith.contains(entry.key)) continue;
      // call back
      if (entry.value(this)) {
        sharedWith.add(entry.key);
      }
    }
  }

  final sharedWith = <String>[];
  void complete() {
    if (hash.isEmpty) hash = makeHash();
    map[hash] = this;
    //sig = UserFractal.active.value?.sign(hash) ?? '';
    ctrl.consume(this);
  }
}
