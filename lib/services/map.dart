import 'dart:async';
import 'dart:collection';

import 'package:axi/flow.dart';
import 'package:fractal/fractal.dart';

import '../models/index.dart';

class MapF<T extends EventFractal> with FlowF<T> {
  final map = <String, T>{};
  final _requests = HashMap<String, List<Completer<T>>>();

  MapF();

  @override
  get list => map.values.toList();

  Future<T> request(String hash) {
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

  complete(String name, T event) {
    //if (map.containsKey(name)) return;
    if (event.state == StateF.removed) {
      map.remove(name);
    } else {
      map[name] = event;
    }

    notify(event);
    final rqs = _requests[name];
    if (rqs == null) return;
    if (event.state != StateF.removed) {
      for (final rq in rqs) {
        rq.complete(event);
        event.notifyListeners();
      }
    }
    rqs.clear();
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
