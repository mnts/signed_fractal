import 'package:fractal_base/models/index.dart';

import '../signed_fractal.dart';
import 'post.dart';

mixin Rewritable on EventFractal {
  final m = MapF<PostFractal>();
  final extensions = MapF<NodeFractal>();

  NodeFractal? extend;

  void onWrite(WriterFractal f) {
    m.complete(f.attr, f);
  }

  Object? operator [](String key) => m[key]?.content ?? extend?[key];

  static Future<T?> ext<T extends EventFractal>(
    MP d,
    Future<T?> Function() cb,
  ) async {
    NodeFractal? extended;
    if (d['extend'] case String extend) {
      if (await EventFractal.map.request(extend) case NodeFractal ext) {
        extended = ext;
        d['type'] ??= extended.type;
      }
    }

    final f = cb();

    final item = await f;
    if (extended != null && item is NodeFractal) {
      item.extend = extended;
      extended.extensions.complete(item.hash, item);
      item.notifyListeners();
    }

    return f;
  }
}

class Writable extends Frac<WriterFractal?> {
  Writable() : super(null);

  @override
  toString() => value?.content ?? '';
}

extension RewritableExt on Rewritable {
  write(String attr, String content) {
    WriterFractal(attr: attr, content: content, to: this).synch();
  }
}

class WriterCtrl<T extends WriterFractal> extends PostCtrl<T> {
  WriterCtrl({
    super.name = 'writer',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[
      Attr('attr', String),
    ],
  });
}

class WriterFractal extends PostFractal {
  static final controller = WriterCtrl(
      extend: PostFractal.controller,
      make: (d) => switch (d) {
            MP() => WriterFractal.fromMap(d),
            Object() || null => throw ('wrong rewriter given')
          });

  @override
  WriterCtrl get ctrl => controller;
  final String attr;

  WriterFractal({
    required this.attr,
    required super.content,
    required super.to,
  });

  @override
  provide(EventFractal into) {
    if (into case Rewritable re) re.onWrite(this);
  }

  @override
  get hashData => [...super.hashData, attr];

  @override
  synch() {
    super.synch();

    ctrl.query("""
      DELETE FROM fractal
      WHERE id IN (
        SELECT writer.id_fractal
        FROM writer
        INNER JOIN event
        ON event.id_fractal=writer.id_fractal
        WHERE event.created_at < ? 
        AND event.`to` = ? AND writer.attr = ?
      );
    """, [createdAt, toHash, attr]);
  }

  WriterFractal.fromMap(MP d)
      : attr = d['attr'],
        super.fromMap(d);

  @override
  MP toMap() => {
        ...super.toMap(),
        'attr': attr,
      };
}
