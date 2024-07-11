import 'package:frac/ref.dart';

import 'models/index.dart';

class FR<V extends EventFractal> {
  late V? value;
  final String ref;
  final Future<V> future;

  FR(this.ref) : future = NetworkFractal.request<V>(ref);
  FR.h(V ev)
      : future = Future.value(ev),
        ref = ev.hash;
  static FR<R>? hn<R extends EventFractal>(R? ev) =>
      ev == null ? null : FR.h(ev);
  static FR<R>? n<R extends EventFractal>(String? refN) =>
      refN == null ? null : FR(refN);
}
