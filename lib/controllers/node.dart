import 'package:fractal/types/index.dart';
import 'package:fractal_base/models/index.dart';
import 'package:signed_fractal/models/node.dart';
import 'events.dart';

class NodeCtrl<T extends NodeFractal> extends EventsCtrl<T> {
  NodeCtrl({
    super.name = 'node',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr(
        'public_key',
        String,
      ),
      Attr(
        'sorted',
        String,
        canNull: true,
      ),
      Attr(
        'private_key',
        String,
        isPrivate: true,
      ),
      Attr(
        'name',
        String,
      ),
    ],
  });

  @override
  final icon = IconF(0xe1f3);
}
