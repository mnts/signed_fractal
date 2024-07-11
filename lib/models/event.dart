import 'dart:async';
import 'package:fractal/lib.dart';
import 'package:fractal_base/fractals/device.dart';
import '../controllers/events.dart';
import '../fr.dart';
import '../mixins/index.dart';
import '../security/key_pair.dart';
import '../services/map.dart';
import 'index.dart';

class EventFractal extends Fractal with Hashed {
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
        isIndex: true,
        isUnique: true,
      ),
      Attr(
        name: 'owner',
        format: 'TEXT',
        isIndex: true,
        canNull: true,
        isImmutable: true,
      ),
      Attr(
        name: 'pubkey',
        format: 'TEXT',
        isImmutable: true,
      ),
      Attr(
        name: 'created_at',
        format: 'INTEGER',
        isImmutable: true,
      ),
      Attr(
        name: 'to',
        format: 'TEXT',
        isImmutable: true,
        isIndex: true,
      ),
      Attr(
        name: 'sig',
        format: 'TEXT',
      ),
      Attr(name: 'sync_at', format: 'INTEGER'),
    ],
  );

  static final map = MapF();
  FR? to;

  @override
  EventsCtrl get ctrl => controller;

  bool get dontStore => false;

  late final String pubkey;
  int createdAt = 0;
  int syncAt;
  String sig = '';

  String get display => hash;

  @override
  String get path => '/-$hash';

  String doHash() {
    hash = Hashed.make(
      ctrl.hashData(
        toMap(),
      ),
    );
    print(hash);
    return hash;
  }

  static bool isHash(String h) => h.length < 52 && h.length > 48;

  consume(EventFractal event) {
    if (event is PostFractal && event.content == 'remove') {
      delete();
      map.notify(this);
    }
    //super.consume(event);
  }

  move() {}

  //@mustCallSuper
  Future<bool> construct() async {
    if (this is Attr) return false;
    ctrl.receive(this);
    return true;
  }

  Future<bool> constructFromMap(MP m) async {
    if (m case {'to': String toHash}) {
      to = FR(toHash);
      consumable();
    }
    return construct();
  }

  EventFractal({
    super.id,
    String hash = '',
    String? pubkey,
    int createdAt = 0,
    this.syncAt = 0,
    UserFractal? owner,
    this.sig = '',
    EventFractal? to,
  })  : owner = FR.hn(owner),
        to = FR.hn(to) {
    this.hash = hash;
    this.pubkey = pubkey ?? _myKeyPair?.publicKey ?? '';
    if (createdAt == 0) this.createdAt = unixSeconds;

    if (to != null) {
      consumable();
    }

    //ownerC.complete(owner);
    ready = construct();
  }

  CatalogFractal? events;
  consumable() async {
    if (to != null) {
      final into = await to!.future;
      provide(into);
      into.consume(this);
    }
  }

  provide(EventFractal into) {
    /*
    print('provide');
    print(into);
    */
  }

  FractalCtrl get eventsSource => WriterFractal.controller;

  @override
  preload([type]) async {
    if (events != null) return 1;
    if (hash.isEmpty) return 0;
    events = CatalogFractal(
      filter: {'to': hash},
      source: eventsSource,
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

  FR<UserFractal>? owner;

  //final ownerC = Completer<UserFractal?>();

  MP get _map => {
        'hash': hash,
        'pubkey': pubkey,
        'owner': owner?.ref,
        'created_at': createdAt,
        'sync_at': syncAt,
        'sig': sig,
        'to': to?.ref ?? '',
      };

  bool get sharable => true;

  /*
  factory EventFractal.get(MP m) {
    final ctrl = FractalCtrl.map[m['name']] as EventsCtrl;
    final hash = Hashed.make(ctrl.hashData(m));
    return EventFractal.map[hash] ?? EventFractal.fromMap(m);
  }
  */

  EventFractal.fromMap(MP d)
      : pubkey = d['pubkey'] ?? '',
        createdAt = d['created_at'] ?? 0,
        syncAt = d['sync_at'] ?? 0,
        sig = d['sig'] ?? '',
        owner = FR.n(d['owner']),
        super(id: d['id']) {
    hash = d['hash'] ?? '';
    owner?.future.then((user) {
      notifyListeners();
    });

    if (d['shared_with'] case List shared) {
      for (var x in shared) {
        switch (x) {
          case String h:
            final device = EventFractal.map[h] as DeviceFractal;
            sharedWith.add(device);
          case DeviceFractal device:
            sharedWith.add(device);
        }
      }
    }

    /*
    final nHash = makeHash();
    if (hash != nHash) {
      //throw throw Exception('hash $hash != $nHash of $type');
      isValid = false;
    }
    */

    ready = constructFromMap(d)
      ..then((b) {
        if (hash.isNotEmpty) {
          complete();
        }
      });
  }

  late Future<bool> ready;

  remove() async {
    await PostFractal(content: 'remove', to: this).synch();
    ctrl.list.removeWhere((f) => f == this);
    EventFractal.map.remove(hash);
    for (var c in CatalogFractal.controller.list) {
      if (c.list.remove(this)) {
        c.notify(this);
      }
    }
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
  synch() async {
    complete();
    //distribute();
    if (!(await ready)) throw ('Item not ready');

    if (createdAt == 2) return;
    await super.synch();
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
    if (hash.isEmpty) doHash();
    if (!map.containsKey(hash)) {
      map.complete(hash, this);
    }
    //sig = UserFractal.active.value?.sign(hash) ?? '';
    //ctrl.consume(this);
  }

  @override
  operator [](key) => switch (key) {
        'to' => to?.ref ?? '',
        'hash' => hash,
        'owner' => owner?.ref,
        'sync_at' => syncAt,
        _ => null,
      };
}
