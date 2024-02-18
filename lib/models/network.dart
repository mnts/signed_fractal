import 'package:fractal_socket/index.dart';
import 'package:signed_fractal/signed_fractal.dart';

class NetworkCtrl<T extends NetworkFractal> extends NodeCtrl<T> {
  NetworkCtrl({
    super.name = 'network',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[],
  });

  @override
  final icon = IconF(0xf0792);
}

class NetworkFractal extends NodeFractal {
  static final controller = NetworkCtrl(
    extend: NodeFractal.controller,
    make: (d) => switch (d) {
      MP() => NetworkFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
  );
  @override
  NetworkCtrl get ctrl => controller;

  static late NetworkFractal active;

  static Future<EventFractal> request(String hash) {
    final rq = EventFractal.map.request(hash);
    if (!EventFractal.map.containsKey(hash)) {
      CatalogFractal.pick(hash, (_) {
        ClientFractal.main?.pick(hash);
      });
    }
    return rq;
  }

  NetworkFractal({
    required super.name,
    super.to,
  });

  NetworkFractal.fromMap(MP d) : super.fromMap(d);

  // Other methods and properties specific to ConnectionFractal
}
