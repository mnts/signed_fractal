import 'dart:async';
import 'dart:convert';

import 'package:fractal_socket/index.dart';
import 'package:signed_fractal/signed_fractal.dart';

class CatalogCtrl<T extends CatalogFractal> extends NodeCtrl<T> {
  CatalogCtrl({
    super.name = 'catalog',
    required super.make,
    required super.extend,
    required super.attributes,
  });

  @override
  final icon = IconF(0xf0d6);
}

class CatalogFractal<T extends Fractal> extends NodeFractal with FlowF<T> {
  static final controller = CatalogCtrl(
      extend: NodeFractal.controller,
      make: (d) => switch (d) {
            MP() => CatalogFractal.fromMap(d),
            _ => throw ('wrong'),
          },
      attributes: <Attr>[
        Attr(
          name: 'filter',
          format: 'TEXT',
          canNull: true,
          isImmutable: true,
        ),
        Attr(
          name: 'source',
          format: 'TEXT',
          canNull: true,
          isImmutable: true,
        ),
        Attr(
          name: 'limit',
          format: 'INTEGER',
          def: '0',
        ),
      ]);

  @override
  CatalogCtrl get ctrl => controller;

  //final FlowF<EventFractal> from;
  final Map<String, dynamic>? filter;
  FractalCtrl<T>? source;

  void _construct() {
    sub.list.forEach(receive);
    sub.listen(receive);
    if (source == null) return;
    EventFractal.map.list.forEach(receive);
    EventFractal.map.listen(receive);
    query();
  }

  bool includeSubTypes;

  CatalogFractal({
    super.to,
    this.filter = const {},
    this.source,
    this.includeSubTypes = true,
    this.limit = 0,
  }) {
    _construct();
  }

  CatalogFractal.fromMap(super.d)
      : filter = d['filter'] is String ? jsonDecode(d['filter']) : null,
        source = FractalCtrl.map['${d['source']}'] as FractalCtrl<T>?,
        limit = d['limit'] ?? 0,
        includeSubTypes = true,
        super.fromMap() {
    _construct();
  }

  int limit;

  @override
  Object? operator [](String key) => switch (key) {
        'filter' => jsonEncode(filter),
        'source' => source?.name ?? '',
        _ => null,
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        for (var a in ctrl.attributes) a.name: this[a.name],
      };

  @override
  dispose() {
    EventFractal.map.unListen(receive);
    super.dispose();
  }

  bool match(T f) {
    //if (f.type != source.name) return false;
    MP filterMap = {
      if (filter != null)
        for (var e in filter!.entries) ...e.value,
    };

    return filterMap.entries.every((e) {
      final value = f[e.key];
      return switch (e.value) {
        String s => (s.length > 2 &&
                s[0] == '%' &&
                s[s.length - 1] == '%' &&
                value is String)
            ? value.contains(
                s.substring(1, s.length - 1),
              )
            : value == s,
        int i => value == i,
        double d => value == d,
        bool b => value == b,
        _ => false,
      };
    });
  }

  receive(Fractal f) {
    if (f is T && match(f)) {
      list.add(f);
      notify(f);
    }
  }

  /*
  static String? findType(dynamic h) {
    final rows = switch (h) {
      String s => EventFractal.controller.select(
          limit: 1,>
          subWhere: {
            'event': {'hash': s},
          },
          includeSubTypes: true,
        ),
      int id => Fractal.controller.select(Future<EventFractal>
          limit: 1,
          subWhere: {
            'event': {'id': id},
          },
          includeSubTypes: true,
        ),
      _ => [],
    };

    return rows.isEmpty ? null : rows[0]['type'];
  }
  */

  static Function(MP)? discovery;
  void query() {
    if (source == null) return;
    final r = source!.select(
      fields: ['hash', 'type'],
      subWhere: filter,
      limit: limit,
      includeSubTypes: true,
    );
    _collect(r);
  }

  @override
  synch() {
    super.synch();
    ClientFractal.main?.sink({
      'cmd': 'subscribe',
      'hash': hash,
    });
    print('sync catalog');
    print(ClientFractal.main?.toMap());
  }

  static final timer = TimedF();
  static final Map<String, Function(String h)?> picking = {};

  static Future<EventFractal> pick(
    String h, [
    void Function(String h)? miss,
  ]) async {
    //List<String> picking = [];
    var fractal = EventFractal.map[h];
    if (fractal != null) return fractal;

    if (picking.containsKey(h)) {
      return EventFractal.map.request(h);
    }

    picking[h] = miss;

    timer.hold(() async {
      final r = EventFractal.controller.select(
        fields: ['hash', 'type'],
        subWhere: {
          'event': {
            'hash': [...picking.keys]
          },
        },
        includeSubTypes: true,
      );

      for (var m in r) {
        final h = m['hash'];
        picking.remove(h);
      }

      for (final entry in picking.entries) {
        final miss = entry.value;
        if (miss != null) miss(entry.key);
      }

      picking.clear();
      await _collect(r);
    }, 40);
    return EventFractal.map.request(h);
  }

  static final timerC = TimedF();
  static Map<String, List<int>> collecting = {};
  static Future _collect(Iterable<Map> frags) {
    //Map<String, List<int>> collecting = {};
    for (var m in frags) {
      final type = m['type'];
      final id = m['id'];
      if (!Fractal.map.containsKey(id)) {
        final ids = collecting[type] ??= [];
        ids.add(id);
      }
    }

    return timerC.hold(() async {
      collecting.forEach((key, value) {
        final ctrl = FractalCtrl.map[key];
        if (ctrl is! EventsCtrl) return;
        final res = ctrl.select(
          subWhere: {
            'fractal': {'id': value},
          },
        );

        for (MP item in res) {
          ctrl.put(item);
        }
      });
      collecting = {};
    }, 100);
  }
}
