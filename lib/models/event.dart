import 'dart:async';
import 'package:fractal/lib.dart';
import 'package:fractal_base/fractals/device.dart';
import '../controllers/events.dart';
import '../mixins/index.dart';
import '../security/key_pair.dart';
import '../services/map.dart';
import 'index.dart';

class EventFractal extends Fractal with Hashed, Consumable<EventFractal> {
  static final controller = EventsCtrl(
    extend: Fractal.controller,
    make: (d) => switch (d) {
      MP() => EventFractal.fromMap(d),
      null || Object() => throw ('wrong event type')
    },
    attributes: [
      Attr(
        name: 'hash',
        format: 'TEXT',
        isUnique: true,
      ),
      Attr(
        name: 'owner',
        format: 'TEXT',
        canNull: true,
      ),
      Attr(
        name: 'pubkey',
        format: 'TEXT',
      ),
      Attr(
        name: 'sig',
        format: 'TEXT',
      ),
      Attr(
        name: 'to',
        format: 'TEXT',
      ),
      Attr(name: 'sync_at', format: 'INTEGER'),
      Attr(
        name: 'created_at',
        format: 'INTEGER',
      ),
    ],
  );

  static final map = MapF();

  @override
  EventsCtrl get ctrl => controller;

  bool get dontStore => false;

  late final String pubkey;
  int createdAt = 0;
  int syncAt;
  String sig = '';

  @override
  String get path => '/-$hash';

  //static late final user = UserNostr();
//"[0,"56c5d5903affd0a3a86672da22e734d6f9c63638cfda9502964b653aec713876",1697109858,"","user","user","mantas"]"

  //final tags = <List<String>>[];
  @override
  List get hashData => [
        super.hashData,
        0,
        pubkey,
        createdAt,
        toHash ?? to?.hash ?? '',
        type,
        //ctrl.name
      ];

  static bool isHash(String h) => h.length < 52 && h.length > 48;

  @override
  consume(EventFractal event) {
    if (event is PostFractal && event.content == 'remove') {
      delete();
      map.notify(this);
    }
    super.consume(event);
  }

  move() {}

  EventFractal({
    super.id,
    String hash = '',
    String? pubkey,
    int createdAt = 0,
    this.syncAt = 0,
    this.owner,
    this.sig = '',
    EventFractal? to,
  }) {
    this.hash = hash;
    this.to = to;
    this.pubkey = pubkey ?? _myKeyPair?.publicKey ?? '';
    if (createdAt == 0) this.createdAt = unixSeconds;
    owner = UserFractal.active.value;
    if (to != null) {
      toHash = to.hash;
      consumable(to);
    }

    ownerC.complete(owner);
  }

  @override
  preload() async {
    if (events != null) return 1;
    if (hash.isEmpty) return 0;
    final q = {'to': hash};
    events = CatalogFractal(
      filter: {'event': q},
      source: controller,
    )
      ..createdAt = 2
      ..synch();

    return 1;
  }

  KeyPair? get _myKeyPair {
    return UserFractal.active.value?.keyPair;
  }

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

  bool get sharable => true;

  EventFractal.fromMap(MP d)
      : pubkey = d['pubkey'] ?? '',
        createdAt = d['created_at'] ?? 0,
        syncAt = d['sync_at'] ?? 0,
        sig = d['sig'] ?? '',
        super(id: d['id']) {
    hash = d['hash'] ?? '';
    final userHash = '${d['owner'] ?? ''}';
    if (userHash.isNotEmpty) {
      NetworkFractal.request(userHash).then((user) {
        if (user is UserFractal) {
          owner = user;
          ownerC.complete(owner);
        }
      });
    } else {
      ownerC.complete();
    }

    if (d case {'to': String toHash}) {
      if (d.isNotEmpty) {
        this.toHash = toHash;
        NetworkFractal.request(toHash).then((r) {
          consumable(r);
        });
      }
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

  String get url => hash;

  int idEvent = 0;
  @override
  synch() {
    complete();
    //distribute();

    if (createdAt == 2) return;
    super.synch();
  }

  setSynched() {
    syncAt = unixSeconds;

    //update field in db
    query(
      'UPDATE event SET sync_at = ? WHERE hash = ?',
      [syncAt, hash],
    );
  }

  /*
  distribute() {
    for (var entry in map.values) {
      if (sharedWith.contains(entry.hash)) continue;
      sharedWith.add(entry.hash);
    }
  }
  */

  final sharedWith = <DeviceFractal>[];
  void complete() {
    if (hash.isEmpty) {
      hash = Hashed.makeHash(hashData);
    }
    if (!map.containsKey(hash)) {
      map.complete(hash, this);
    }
    //sig = UserFractal.active.value?.sign(hash) ?? '';
    //ctrl.consume(this);
  }

  @override
  operator [](key) => switch (key) {
        'to' => toHash,
        'hash' => hash,
        'sync_at' => syncAt,
        _ => null,
      };
}
