import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:fractal/lib.dart';
import 'package:fractal/types/file.dart';
import 'package:signed_fractal/models/post.dart';
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
  int syncAt;
  String sig = '';

  bool get isSaved => hash.isNotEmpty;

  @override
  String get path => '/${ctrl.name}/$hash';

  signa() {
    if (hash.isEmpty) {
      throw Exception(
        'event is not complete for signature',
      );
    }
  }

  //static late final user = UserNostr();
//"[0,"56c5d5903affd0a3a86672da22e734d6f9c63638cfda9502964b653aec713876",1697109858,"","user","user","mantas"]"

  //final tags = <List<String>>[];
  List get hashData =>
      [0, pubkey, createdAt, toHash ?? to?.hash ?? '', type, ctrl.name];

  makeHash([data]) {
    data ??= hashData;
    String serializedEvent = json.encode([
      ...data.map((d) => d ?? ''),
    ]);
    final h = Uint8List.fromList(
      sha256.convert(utf8.encode(serializedEvent)).bytes,
    );
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
    this.owner,
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

    ownerC.complete(owner);
  }

  KeyPair? get _myKeyPair => UserFractal.active.value?.keyPair;
  bool get own => _myKeyPair != null && pubkey == _myKeyPair!.publicKey;
  //bool get own => active.value == owner;

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };

  UserFractal? owner;

  final ownerC = Completer<UserFractal?>();

  MP get _map => {
        'hash': hash,
        'pubkey': pubkey,
        'owner': owner?.hash ?? UserFractal.active.value?.hash,
        'created_at': createdAt,
        'sync_at': syncAt,
        'sig': sig,
        'to': to?.hash ?? toHash ?? '',
      };

  String? toHash;

  bool get sharable => true;

  EventFractal.fromMap(MP d)
      : hash = d['hash'] ?? '',
        pubkey = d['pubkey'] ?? '',
        createdAt = d['created_at'] ?? 0,
        syncAt = d['sync_at'] ?? 0,
        sig = d['sig'] ?? '',
        super(id: d['id']) {
    final userHash = '${d['owner'] ?? ''}';
    if (userHash.isNotEmpty) {
      map.request(userHash).then((user) {
        if (user is UserFractal) {
          owner = user;
          ownerC.complete(owner);
        }
      });
    } else {
      ownerC.complete();
    }

    if (d case {'to': String toHash}) {
      this.toHash = toHash;
      map.request(toHash).then(_consume);
    }

    /*
    final nHash = makeHash();
    if (hash != nHash) {
      //throw throw Exception('hash $hash != $nHash of $type');
      isValid = false;
    }
    */

    if (hash.isNotEmpty) {
      complete();
    }
  }

  remove() {
    final post = PostFractal(content: 'remove', to: this)..synch();
    print(post.hashData);
  }

  bool isValid = true;

  /*
  static final listeners = <String, Function(EventFractal)>{};
  static listen(String name, Function(EventFractal) cb) {
    listeners[name] = (cb);
  }

  static unListen(String name) {
    listeners.remove(name);
  }
  */

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
    if (event is PostFractal && event.content == 'remove') {
      delete();
      map.notify(this);
    }
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
    complete();
    //distribute();

    syncAt = unixSeconds;
    super.synch();
  }

  /*
  distribute() {
    for (var entry in map.values) {
      if (sharedWith.contains(entry.hash)) continue;
      sharedWith.add(entry.hash);
    }
  }
  */

  final sharedWith = <String>[];
  void complete() {
    if (hash.isEmpty) hash = makeHash();
    if (!map.containsKey(hash)) {
      map.complete(hash, this);
    }
    //sig = UserFractal.active.value?.sign(hash) ?? '';
    //ctrl.consume(this);
  }
}
