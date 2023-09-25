import 'package:signed_fractal/signed_fractal.dart';

class SortedFrac<T extends EventFractal> extends Frac<List<T>> {
  SortedFrac(super.value, {this.onMove});
  Function()? onMove;
  bool dontNotify = false;

  order(T f, [int? pos]) {
    if (pos == null || value.isEmpty) {
      value.add(f);
    } else {
      value.remove(f);
      value.insert(pos, f);
    }
  }

  int get length => value.length;

  Future<void> fromArray(List<String> list) async {
    dontNotify = true;
    value.clear();
    for (var i = 0; i < list.length; i++) {
      final f = await EventFractal.map.request(list[i]);
      if (f is T) {
        order(f, i);
      }
    }
  }

  fromString(String? s) {
    if (s == null) return;
    fromArray(s.split(','));
  }

  @override
  toString() => value.map((f) => f.hash).join(',');
}
