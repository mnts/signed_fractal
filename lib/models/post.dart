import '../controllers/events.dart';
import '../signed_fractal.dart';
import 'event.dart';

class PostCtrl<T extends PostFractal> extends EventsCtrl<T> {
  PostCtrl({
    super.name = 'post',
    required super.make,
    required super.extend,
    required super.attributes,
  });
}

class PostFractal extends EventFractal {
  static final controller = PostCtrl(
    extend: EventFractal.controller,
    make: (d) => switch (d) {
      MP() => PostFractal.fromMap(d),
      _ => throw ('wrong rewriter given')
    },
    attributes: <Attr>[
      Attr(
        name: 'content',
        format: 'TEXT',
        isImmutable: true,
      ),
      Attr(
        name: 'file',
        format: 'TEXT',
        isImmutable: true,
      ),
      Attr(
        name: 'kind',
        format: 'INTEGER',
        def: '0',
      ),
    ],
  );

  PostCtrl get ctrl => controller;

  final String content;
  FileF? file;
  int kind;

  PostFractal({
    required this.content,
    this.file,
    super.to,
    this.kind = 0,
    super.owner,
  });

  PostFractal.fromMap(MP d)
      : content = '${d['content']}',
        kind = d['kind'] ?? 0,
        file = d['file'] is String && (d['file'] as String).isNotEmpty
            ? FileF(d['file'])
            : null,
        super.fromMap(d);

  @override
  operator [](String key) => switch (key) {
        'content' => content,
        'file' => file?.name ?? '',
        _ => super[key],
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        for (var a in controller.attributes) a.name: this[a.name],
      };
}
