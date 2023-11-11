import 'package:fractal/types/index.dart';
import 'package:fractal_base/models/index.dart';
import 'package:signed_fractal/models/node.dart';
import '../models/event.dart';
import 'events.dart';

class NodeCtrl<T extends NodeFractal> extends EventsCtrl<T> {
  NodeCtrl({
    super.name = 'node',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr(
        'sorted',
        String,
        canNull: true,
      ),
      Attr(
        'name',
        String,
      ),
      Attr(
        'extend',
        String,
        canNull: true,
      ),
    ],
  });

  @override
  final icon = IconF(0xf560);
}
