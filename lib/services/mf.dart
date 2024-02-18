import 'package:fractal_socket/index.dart';
import 'package:signed_fractal/signed_fractal.dart';

class MF<T extends EventFractal> extends MapF<T> {
  MF() {}

  @override
  discover(String h) {
    ClientFractal.main?.sink({
      'cmd': 'search',
      'type': UserFractal.controller.name,
      'where': {'name': h},
    });
  }
}
