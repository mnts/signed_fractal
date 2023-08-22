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
        'private_key',
        String,
        isPrivate: true,
      ),
    ],
  });
}
