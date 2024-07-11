import 'package:signed_fractal/signed_fractal.dart';

import '../fr.dart';
import 'index.dart';

class ConnectionCtrl<T extends ConnectionFractal> extends InteractionCtrl<T> {
  ConnectionCtrl({
    super.name = 'connection',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[],
  });
  @override
  final icon = IconF(0xf858);
}

class ConnectionFractal extends InteractionFractal {
  static final controller = ConnectionCtrl(
    extend: InteractionFractal.controller,
    make: (d) => switch (d) {
      MP() => ConnectionFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
  );
  @override
  ConnectionCtrl get ctrl => controller;

  final NodeFractal from;

  ConnectionFractal({
    required this.from,
    required super.to,
  });

  ConnectionFractal.fromMap(super.d)
      : from = EventFractal.map[d['from']] as NodeFractal,
        super.fromMap();

  // Other sfdgfdgsdfgmethods and properties specific to ConnectionFractal
}
