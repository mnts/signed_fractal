import 'package:signed_fractal/signed_fractal.dart';

class SortedFrac<T extends EventFractal> extends Frac<List<T>> {
  SortedFrac(super.value, {this.onMove});
  Function()? onMove;
  bool dontNotify = false;

  order(T f, [int? pos]) {
    value.remove(f);
    if (pos == null || value.isEmpty || pos > value.length) {
      value.add(f);
    } else {
      value.insert(pos, f);
    }
    if (!dontNotify) notifyListeners();
  }

  remove(T ev) {
    value.remove(ev);
    notifyListeners();
  }

  int get length => value.length;

  Future fromArray(List<String> list) async {
    dontNotify = true;
    value.clear();
    for (var i = 0; i < list.length; i++) {
      final h = list[i];
      final f = await NetworkFractal.request(h);
      if (f is T) {
        order(f, i);
      }
    }
    dontNotify = false;
  }

  fromString(String? s) async {
    if (s == null) return;
    await fromArray(s.split(','));
    notifyListeners();
  }

  add(T f) {
    value.add(f);
    notifyListeners();
  }

  @override
  toString() => value.map((f) => f.hash).join(',');
}
