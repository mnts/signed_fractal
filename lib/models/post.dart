import '../controllers/events.dart';
import '../signed_fractal.dart';
import 'event.dart';

class PostCtrl<T extends PostFractal> extends EventsCtrl<T> {
  PostCtrl({
    super.name = 'post',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[
      Attr('content', String),
      Attr('file', String),
    ],
  });
}

class PostFractal extends EventFractal {
  static final controller = PostCtrl(
    extend: EventFractal.controller,
    make: (d) => switch (d) {
      MP() => PostFractal.fromMap(d),
      _ => throw ('wrong rewriter given')
    },
  );

  PostCtrl get ctrl => controller;

  final String content;
  FileF? file;

  PostFractal({
    required this.content,
    this.file,
    super.to,
  });

  PostFractal.fromMap(MP d)
      : content = '${d['content']}',
        super.fromMap(d) {
    if (d case {'file': String fileHash}) {
      if (fileHash.isNotEmpty) file = FileF(fileHash);
    }
  }

  List get hashData => [...super.hashData, content, file?.name ?? ''];

  @override
  MP toMap() => {
        ...super.toMap(),
        'content': content,
        'file': file?.name ?? '',
      };
}
