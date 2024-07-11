import 'dart:async';
import 'package:fractal/lib.dart';
import '../mixins/index.dart';
import '../models/event.dart';
import '../models/rewriter.dart';

class EventsCtrl<T extends EventFractal> extends FractalCtrl<T> with FlowF<T> {
  EventsCtrl({
    super.name = 'event',
    required super.make,
    required super.extend,
    required super.attributes,
  }) {
    if (extend case FractalCtrl ext) ext.sub.add(this);
  }

  var transformers = <String, T Function(T, Rewritable)>{};

  @override
  final icon = IconF(0xe22d);

  /*
  //final map = MapF<T>();
  List<T> findt(MP m) {
    final list = <T>[...map.values];
    if (m case {'since': int time}) {
      time;
    }
    return list;
  }
  */

  List hashData(MP m) {
    if (extend case EventsCtrl ext) {
      return [...ext.hashData(m), ...immutableData(m)];
    }

    return [[], 0, ...immutableData(m), name];
  }

  List immutableData(MP m) => [
        ...attributes.where((a) => a.isImmutable).map((a) => (m[a.name] ?? '')),
      ];

  bool dontNotify = false;

  void preload(Iterable json) {
    dontNotify = true;
    for (MP item in json) {
      if (item['id'] is int && !Fractal.map.containsKey(item['id'])) {
        put(item);
      }
    }
    dontNotify = false;
  }

  @override
  List<EventsCtrl> get top => super.top.map((c) => c as EventsCtrl).toList();

  Future<T> put(MP item) async {
    //final ctrl = FractalCtrl.map[item['name']] as EventsCtrl;
    item = {
      ...item,
    };

    if (!item.containsKey('hash')) {
      item['hash'] = Hashed.make(hashData(item));
    }

    final evf = EventFractal.map[item['hash']] as T?;

    if (evf != null) return evf;

    if (item['created_at'] == 0) {
      print('zero_created');
      print(item);
      if (item['sync_at'] case int syncAt when syncAt > 0) {
        return await make(item);
      }

      final res = await select(
        where: {'hash': item['hash']},
      );

      if (res.isNotEmpty) {
        return make(res[0]);
      }

      return make(item);
    }

    return evf ?? await make(item);
  }

  /*
  collect({required Iterable<int> only}) {
    final res = select(
      where: {'id': only},
    );
    preload(res);
  }
  */

  /*
  final _consumers = <Function(T)>[];
  consumer(Function(T) cb) {
    _consumers.add(cb);
  }

  consume(T event) {
    for (var c in _consumers) {
      c(event);
    }
  }
  */

  //static final map = <String, EventsCtrl>{};

  @override
  init() async {
    super.init();
    //collect();
    //CREATE INDEX acctchng_magnitude ON account_change(acct_no, abs(amt));
  }

  //Stream? _watcher;
  Future _load() async {
    /*
    final select = db.select(db.events);
    //select.where((tbl) => tbl.syncAt.equals(0));
    select.orderBy([
      (tbl) => OrderingTerm(
            expression: tbl.createdAt,
            mode: OrderingMode.desc,
          ),
    ]);

    //_watcher = select.watch()..listen((event) {});

    select.get().then((list) {
      return preload([]);
      preload(
        list.map((row) {
          final m = row.toJson();
          if (m['id'] is! int) {
            m['hash'] = m.remove('id');
          }
          return m;
        }),
      );
    });
    /*
    (rows) {
      rows.forEach((row) {
        final m = row.toJson();
        m.remove('syncAt');
        m.remove('i');
        m['created_at'] = m['createdAt'];
        m['tags'] = [];
        m.remove('createdAt');
        //relay.send(m);
      });

      if (rows.isNotEmpty) Events.synched();
    };
    */
    */
  }
}
