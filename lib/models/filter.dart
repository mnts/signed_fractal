import 'dart:async';
import 'dart:convert';

import 'package:signed_fractal/signed_fractal.dart';

class FilterCtrl<T extends FilterFractal> extends AttrCtrl<T> {
  FilterCtrl({
    super.name = 'filter',
    required super.make,
    required super.extend,
    required super.attributes,
  });

  @override
  final icon = IconF(0xf5a6);
}

enum Qf {
  eq,
  neq,
  gt,
  lt,
  gte,
  lte,
}

class FilterFractal extends Attr {
  static final controller = FilterCtrl(
      extend: Attr.controller,
      make: (d) => switch (d) {
            MP() => FilterFractal.fromMap(d),
            _ => throw ('wrong'),
          },
      attributes: <Attr>[
        Attr(
          name: 'qf',
          format: 'INTEGER',
        ),
      ]);

  @override
  FilterCtrl get ctrl => controller;

  @override
  get hashData => [
        ...super.hashData,
        filter,
      ];

  //final FlowF<EventFractal> from;
  final Map<String, MP>? filter;
  Qf qf;

  void _construct() {}

  FilterFractal({
    super.to,
    this.qf = Qf.eq,
    this.filter = const {},
    required super.name,
    required super.format,
  }) {
    _construct();
  }

  FilterFractal.fromMap(super.d)
      : filter = d['filter'] is String ? jsonDecode(d['filter']) : null,
        qf = Qf.values[d['qf'] ?? 0],
        super.fromMap() {
    _construct();
  }

  @override
  Object? operator [](String key) => switch (key) {
        'qf' => qf.index,
        _ => null,
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        for (var a in ctrl.attributes) a.name: this[a.name],
      };

  bool match(Fractal f) {
    //if (f.type != source.name) return false;
    MP filterMap = {
      if (filter != null)
        for (var e in filter!.entries) ...e.value,
    };

    return filterMap.entries.every((e) {
      final value = f[e.key];
      if (value is! String) return false;
      if (e.value is! String) return false;
      final qs = e.value as String;
      if (qs.length > 2 && qs[0] == '%' && qs[qs.length - 1] == '%') {
        final s = qs.substring(1, qs.length - 1);
        return value.contains(s);
      }
      return value == e.value;
    });
  }
}
