import 'dart:async';
import 'dart:collection';
import 'package:fractal/fractal.dart';
import '../models/index.dart';

class MapF<T extends EventFractal> with FlowF<T> {
  final map = <String, T>{};
  final _requests = HashMap<String, List<Completer<T>>>();

  MapF();

  @override
  get list => map.values.toList();

  Future<T> request(String hash) async {
    final comp = Completer<T>();
    if (map.containsKey(hash)) {
      comp.complete(map[hash]);
    } else {
      if (_requests.containsKey(hash)) {
        _requests[hash]!.add(comp);
      } else {
        _requests[hash] = [comp];
      }
    }
    return comp.future;
  }

  discover(String key) {}

  bool containsKey(String key) => map.containsKey(key);

  @override
  notify(T fractal) {
    if (fractal.state == StateF.removed) {
      cleanUp();
    }
    super.notify(fractal);
  }

  cleanUp() {
    map.removeWhere((key, f) => f.state == StateF.removed);
  }

  bool complete(String name, T event) {
    if (event.state == StateF.removed) {
      map.remove(name);
    } else {
      final current = map[name];
      if (current == null || current.createdAt <= event.createdAt) {
        map[name] = event;
      } else {
        return false;
      }
    }

    notify(event);
    final rqs = _requests[name];
    if (rqs == null) return true;
    if (event.state != StateF.removed) {
      for (final rq in rqs) {
        rq.complete(event);
        event.notifyListeners();
      }
    }
    rqs.clear();
    return true;
  }

  Iterable<T> get values => map.values;

  operator []=(String key, T val) {
    if (!map.containsKey(key)) {
      complete(key, val);
    }
  }

  T? operator [](String key) {
    return map[key]; // ??= word.frac() ?? Frac('');
  }
}
