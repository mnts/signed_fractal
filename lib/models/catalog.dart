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
          name: 'mode',
          format: 'TEXT',
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

  T? byId(int id) {
    try {
      return list.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  //final FlowF<EventFractal> from;
  final Map<String, dynamic>? filter;
  FractalCtrl<T>? source;
  List<String> get mode => [
        if (!includeSubTypes) 'noSub',
      ];

  bool includeSubTypes;
  bool onlyLocal;

  CatalogFractal({
    super.to,
    this.filter = const {},
    this.source,
    this.includeSubTypes = true,
    this.limit = 0,
    this.onlyLocal = false,
  }) {
    _construct();
  }

  CatalogFractal.fromMap(super.d)
      : filter = switch (d['filter']) {
          String s => jsonDecode(s),
          Map m => {...m},
          _ => null,
        },
        source = FractalCtrl.map['${d['source']}'] as FractalCtrl<T>?,
        limit = d['limit'] ?? 0,
        includeSubTypes = !"${d['mode']}".contains('noSub'),
        onlyLocal = false,
        super.fromMap() {
    _construct();
  }

  int limit;

  @override
  Object? operator [](String key) => switch (key) {
        'filter' => jsonEncode(filter),
        'source' => source?.name ?? '',
        'mode' => [...mode..sort()].join(','),
        _ => super[key],
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        for (var a in ctrl.attributes) a.name: this[a.name],
      };

  @override
  dispose() {
    //sub.unListen(receive);
    if (source case EventsCtrl evCtrl) {
      evCtrl.unListen(receive);
      if (includeSubTypes) {
        for (var c in evCtrl.top) {
          c.unListen(receive);
        }
      }
      super.dispose();
    }
  }

  bool matchSource(T f) {
    if (source != null) {
      if (!includeSubTypes && f.type != source!.name) return false;
      if (includeSubTypes &&
          !(f.type == source!.name ||
              source!.top.any((c) => c.name == f.type))) {
        return false;
      }
    }
    return true;
  }

  bool match(T f) {
    if (!matchSource(f)) return false;

    return filter?.entries.every((e) {
          dynamic value = f[e.key];
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
            Map m => m.entries
                .map((e) => switch (e.key) {
                      'gt' => value > e.value,
                      'gte' => value >= e.value,
                      'lt' => value < e.value,
                      'lte' => value <= e.value,
                      _ => '',
                    })
                .every((element) => false),
            double d => value == d,
            false => value == false || '$value' == '' || value == null,
            true => value == true || '${value ?? ''}'.isNotEmpty,
            _ => false,
          };
        }) ??
        true;
  }

  @override
  receive(Fractal f) {
    print('receve($f)');

    if (f is T && match(f)) {
      if (f.state == StateF.removed) {
        list.remove(f);
        notifyListeners();
      }
      super.receive(f);
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

  void _construct() {}

  bool _initiated = false;
  @override
  initiate() async {
    if (_initiated) return 0;
    //sub.list.forEach(receive);
    //sub.listen(receive);
    if (source case EventsCtrl evCtrl) {
      evCtrl.list.forEach(receive);
      evCtrl.listen(receive);
      if (includeSubTypes) {
        for (var c in evCtrl.top) {
          c.list.forEach(receive);
          c.listen(receive);
        }
      }
    }

    await query();
    _initiated = true;
    return super.initiate();
  }

  static Function(MP)? discovery;
  Future<List<MP>> query() async {
    if (source == null) return [];
    final r = await source!.select(
      fields: [
        'hash',
        'type',
      ],
      where: filter,
      limit: limit,
      includeSubTypes: includeSubTypes,
    );
    _collect(r);
    return r;
  }

  @override
  List<T> listen(fn) {
    initiate();
    return super.listen(fn);
  }

  @override
  synch() async {
    await super.synch();
    await initiate();
    if (!onlyLocal) {
      ClientFractal.main?.sink({
        'cmd': 'subscribe',
        'hash': hash,
      });
      print('sync catalog');
    }
    print(ClientFractal.main?.toMap());
  }

  unSynch() {
    super.synch();
    if (!onlyLocal) {
      ClientFractal.main?.sink({
        'cmd': 'unsubscribe',
        'hash': hash,
      });
      print('unSync catalog');
    }
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
      final r = await EventFractal.controller.select(
        fields: ['hash', 'type'],
        where: {
          'hash': [...picking.keys]
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
      collecting.forEach((key, value) async {
        final ctrl = FractalCtrl.map[key];
        if (ctrl is! EventsCtrl) return;
        final res = await ctrl.select(
          where: {'id': value},
        );

        for (MP item in res) {
          await ctrl.put(item);
        }
      });
      collecting = {};
    }, 100);
  }
}
