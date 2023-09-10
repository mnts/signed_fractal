import 'package:fractal_base/models/index.dart';

import '../signed_fractal.dart';

abstract class Rewritable extends EventFractal {
  void onWrite(WriterFractal rewriter) {}
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

class WriterCtrl<T extends WriterFractal> extends EventsCtrl<T> {
  WriterCtrl({
    super.name = 'writer',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[
      Attr('attr', String),
    ],
  });
}

class WriterFractal extends EventFractal {
  static final controller = WriterCtrl(
      extend: EventFractal.controller,
      make: (d) => switch (d) {
            MP() => WriterFractal.fromMap(d),
            Object() || null => throw ('wrong rewriter given')
          });

  @override
  WriterCtrl get ctrl => controller;
  final String attr;

  WriterFractal({
    super.id,
    required this.attr,
    required super.content,
    super.file,
    required super.to,
  });

  @override
  provide(EventFractal into) {
    if (into case Rewritable re) re.onWrite(this);
  }

  @override
  get hashData => [...super.hashData, attr];

  WriterFractal.fromMap(MP d)
      : attr = d['attr'],
        super.fromMap(d);

  @override
  MP toMap() => {
        ...super.toMap(),
        'attr': attr,
      };
}
