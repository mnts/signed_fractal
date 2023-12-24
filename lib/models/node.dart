import 'dart:async';

import 'package:app_fractal/index.dart';

import '../security/key_pair.dart';
import '../signed_fractal.dart';

class NodeFractal extends EventFractal with Rewritable, InteractiveFractal {
  static final controller = NodeCtrl(
    extend: EventFractal.controller,
    make: (d) => switch (d) {
      MP() => NodeFractal.fromMap(d),
      (String s) => NodeFractal(name: s),
      Object() || null => throw ('wrong event type')
    },
  );

  static final flow = TypeFilter<NodeFractal>(
    EventFractal.map,
  );

  final SortedFrac<EventFractal> sorted;

  Timer? sortTimer;
  sort() {
    sortTimer?.cancel();
    sortTimer = Timer(const Duration(seconds: 2), () {
      write('sorted', sorted.toString());
      sortTimer = null;
    });
  }

  @override
  //String get path => '/${ctrl.name}/$name';

  @override
  NodeCtrl get ctrl => controller;

  NodeFractal({
    super.to,
    this.name = '',
    NodeFractal? extend,
    KeyPair? keyPair,
    List<EventFractal>? sub,
  }) : sorted = SortedFrac(sub ?? []) {
    if (extend != null) {
      this.extend = extend;
    }
    construct();
  }

  construct() {}

  @override
  consume(event) {
    if (event case NodeFractal node) {
      sub.complete(node.name, node);
    }
    super.consume(event);
    if (state == StateF.removed) {
      if (to case NodeFractal container) {
        container.sub.notify(this);
      }
    }
  }

  NodeFractal require(String name) {
    final node = sub[name] ?? (NodeFractal(name: name, to: this)..synch());
    return node;
  }

  final sub = MapF<NodeFractal>();

  Future<List<NodeFractal>> discover() async {
    return [];
  }

  /*List<NodeFractal> */ find() {
    final tableName = NodeFractal.controller.name;

    Iterable resIds = ctrl.db.select("""
SELECT id_fractal as id FROM $tableName WHERE to = ?
""", [hash]);

    final rids = resIds.map((r) => r['id']);
    final ids = <int>[];
    for (var rId in rids) {
      if (rId is int && !Fractal.map.containsKey(rId)) {
        ids.add(rId);
      }
    }

    final res = ctrl.select(
      only: ids,
    );

    for (MP item in res) {
      ctrl.put(item);
    }
  }

  String name;

  @override
  get hashData => [...super.hashData, name];

  NodeFractal.fromMap(MP d)
      : name = d['name'] ?? '',
        sorted = SortedFrac([])
          ..fromString(
            d['sub'],
          ),
        super.fromMap(d) {
    construct();
  }

  MP get _map => {
        'name': name,
        'extend': extend?.hash,
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };

  String get display =>
      title.value?.content ??
      name
          .replaceAll(
            RegExp('[^A-Za-z0-9-]'),
            ' ',
          )
          .toTitleCase();
  final title = Writable();
  FileF? image;
  /*
  FileF? get image => _image ?? extend?.image;
  set image(FileF? v) {
    _image = v;
  }
  */

  var tags = <String>[];

  @override
  onWrite(f) {
    switch (f.attr) {
      case 'title':
        title.value = f;
      case 'tags':
        (f.content.isEmpty) ? tags.clear() : tags = f.content.split(' ');
        notifyListeners();
      case 'sorted':
        sorted.fromString(f.content);
      case 'image':
        image = ImageF(f.content);
        notifyListeners();
      default:
        super.onWrite(f);
    }
  }
}
