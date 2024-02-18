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
    required super.attributes,
  });

  @override
  final icon = IconF(0xe1ae);
}
