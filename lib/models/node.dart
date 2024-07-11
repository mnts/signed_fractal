import 'dart:async';

import 'package:app_fractal/index.dart';
import 'package:expressions/expressions.dart';

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
    attributes: [
      Attr(
        name: 'sorted',
        format: 'TEXT',
        canNull: true,
      ),
      Attr(
        name: 'name',
        format: 'TEXT',
        isImmutable: true,
      ),
      Attr(
        name: 'extend',
        format: 'TEXT',
        canNull: true,
        isImmutable: true,
      ),
      Attr(
        name: 'price',
        format: 'REAL',
        isImmutable: false,
        canNull: true,
      ),
    ],
    //indexes: {},
  );

  @override
  NodeCtrl get ctrl => controller;

  static final flow = TypeFilter<NodeFractal>(
    EventFractal.map,
  );

  final SortedFrac<EventFractal> sorted;

  @override
  get display {
    if (this['display'] case String disp) {
      final exp = Expression.parse(disp);
      exp.toTokenString();
      if (disp[0] == '.') {
        if (this[disp.substring(1)] case String reDisplay) return reDisplay;
      }
    }
    return title.value?.content ??
        name
            .replaceAll(
              RegExp('[^A-Za-z0-9-]'),
              ' ',
            )
            .toTitleCase;
  }

  Timer? sortTimer;
  sort() {
    sortTimer?.cancel();

    sortTimer = Timer(const Duration(seconds: 2), () {
      write('sorted', sorted.toString());
      sortTimer = null;
    });
  }

  double? price;

  @override
  //String get path => '/${ctrl.name}/$name';

  NodeFractal({
    super.to,
    this.name = '',
    this.price,
    NodeFractal? extend,
    KeyPair? keyPair,
    List<EventFractal>? sub,
  }) : sorted = SortedFrac(sub ?? []) {
    if (extend != null) {
      this.extend = extend;

      extend.addListener(() {
        notifyListeners();
      });
    }
  }

  @override
  Future<bool> constructFromMap(m) async {
    if (m['extend'] case String extendStr) {
      if (await NetworkFractal.request(extendStr) case NodeFractal ext) {
        await ext.ready;
        extend = ext;
        //m['type'] ??= extend!.type;
      }
    }

    if (extend != null) {
      extend!.addListener(() {
        notifyListeners();
      });
      extend!.extensions.complete(hash, this);
      notifyListeners();

      if (events != null) {
        extend!.preload();
      }
    }

    return super.constructFromMap(m);
  }

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
    final node = sub[name] ??
        (NodeFractal(name: name, to: this)
          ..createdAt = 2
          ..synch());
    return node;
  }

  late final _catalog = CatalogFractal(
    filter: {'to': hash},
    source: NodeFractal.controller,
  )
    ..createdAt = 2
    ..synch();

  final sub = MapF<NodeFractal>();

  @override
  remove() async {
    await super.remove();
    if ((await to?.future) case NodeFractal node) {
      node.sub.notify(this);
    }
  }

  Future<List<NodeFractal>> discover() async {
    return [];
  }

  /*List<NodeFractal>  find() {
    final tableName = ctrl.name;

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
      where: {'id': ids},
    );

    for (MP item in res) {
      ctrl.put(item);
    }
  }
  */

  String name;

  NodeFractal.fromMap(super.d)
      : name = d['name'] ?? '',
        price = d['price']?.toDouble(),
        sorted = SortedFrac([])
          ..fromString(
            d['sub'],
          ),
        super.fromMap();

  MP get _map => {
        'name': name,
        'price': price,
        'extend': extend?.hash,
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };

  final title = Writable();
  FileF? file;
  FileF? image;
  FileF? video;
  String? description;

  @override
  preload([type]) async {
    //myInteraction;
    await ready;
    if (type == 'node') _catalog;

    if (extend != null) {
      await extend!.ready;
      extend!.preload(type);
    }
    return super.preload(type);
  }
  /*
  FileF? get image => _image ?? extend?.image;
  set image(FileF? v) {
    _image = v;
  }
  */

  var tags = <String>[];

  @override
  onWrite(f) {
    final ok = super.onWrite(f);
    if (ok) {
      switch (f.attr) {
        case 'title':
          title.value = f;
        case 'price':
          final val = double.tryParse(f.content);
          if (val != null && price != val) {
            controller.update({
              'price': val,
            }, id);
            price = val;
            notifyListeners();
          }
        case 'description':
          description = f.content;
          notifyListeners();
        case 'tags':
          (f.content.isEmpty) ? tags.clear() : tags = f.content.split(' ');
          notifyListeners();
        case 'sorted':
          sorted.fromString(f.content);
          print(sorted);
        case 'image':
          image = ImageF(f.content);
          notifyListeners();
        case 'video':
          video = FileF(f.content);
          notifyListeners();

        default:
          notifyListeners();
        //super.onWrite(f);
      }
    }
    return ok;
  }

  @override
  operator [](String key) => switch (key) {
        'name' => name,
        'price' => price ?? extend?.price ?? super[key],
        _ => super[key] ?? m[key]?.content ?? extend?[key],
      };
}
