import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fractal/lib.dart';
import 'package:fractal/types/file.dart';
import '../controllers/events.dart';
import 'package:convert/convert.dart';

class EventFractal extends Fractal {
  static final controller = EventsCtrl(
    extend: Fractal.controller,
    make: (d) => switch (d) {
      MP() => EventFractal.fromMap(d),
      null || Object() => throw ('wrong event type')
    },
  );
  @override
  FractalCtrl get ctrl => controller;

  bool get dontStore => false;

  String hash = '';
  final String pubkey;
  int createdAt = 0;
  final int syncAt;
  final int expiresAt;
  final int kind;
  final String content;
  final String name;
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

  static Map<String, dynamic> _make(Map<String, dynamic> m) {
    return map;
  }

  final tags = <List<String>>[];
  List get hashData => [0, pubkey, createdAt, type, content];

  makeHash() {
    String serializedEvent = json.encode(hashData);
    print('generate hash for $type');
    print(serializedEvent);
    List<int> h = sha256.convert(utf8.encode(serializedEvent)).bytes;
    return hex.encode(h);
  }

  EventFractal? to;

  EventFractal({
    super.id,
    this.hash = '',
    this.pubkey = 'user pub key',
    int createdAt = 0,
    this.syncAt = 0,
    this.expiresAt = 0,
    this.kind = 1,
    this.content = '',
    this.file,
    this.sig = '',
    this.name = '',
    this.to,
  }) {
    if (createdAt == 0) this.createdAt = unixSeconds;
    if (hash.isNotEmpty) map[hash] = this;
    if (to != null) _consume(to!);
  }

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };

  MP get _map => {
        'hash': hash,
        'pubkey': pubkey,
        'created_at': createdAt,
        'sync_at': syncAt,
        'expires_at': expiresAt,
        'kind': kind,
        'content': content,
        'file': file?.name ?? '',
        'sig': sig,
        'name': sig,
        'pid': sig,
        'to': toHash ?? to?.hash ?? '',
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
        name = d['name'] ?? '',
        super(id: d['id']) {
    if (d case {'file': String fileHash}) {
      file = FileF(fileHash);
    }

    if (d case {'to': String toHash}) {
      toHash = toHash;
      request(toHash).then(_consume);
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
    provide(into);
    into.consume(this);
  }

  consume(EventFractal event) {}

  provide(EventFractal event) {}

  static final map = <String, EventFractal>{};
  static final _requests = HashMap<String, List<Completer<EventFractal>>>();
  static Future<EventFractal> request(String hash) {
    final comp = Completer<EventFractal>();
    if (map.containsKey(hash)) {
      comp.complete(map[hash]);
    } else {
      if (_requests.containsKey(hash)) {
        _requests[hash]!.add(comp);
      } else {
        _requests[hash] = [comp];
      }
    }
    return comp.future;
  }

  String get url => hash;

  int idEvent = 0;
  @override
  synch() {
    print('synch event ');
    if (map.containsKey(hash) && EventFractal.map.containsKey(hash)) {
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
    final rqs = _requests[hash];
    if (rqs == null) return;
    for (final rq in rqs) {
      rq.complete(this);
      notifyListeners();
    }
    rqs.clear();
  }
}
