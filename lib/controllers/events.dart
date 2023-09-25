import 'dart:async';
import 'package:fractal/lib.dart';
import 'package:fractal_base/extensions/sql.dart';
import 'package:fractal_base/models/index.dart';
import '../models/event.dart';
import '../services/map.dart';

class EventsCtrl<T extends EventFractal> extends FractalCtrl<T> {
  EventsCtrl({
    super.name = 'event',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr('kind', int),
      Attr(
        'hash',
        String,
        isUnique: true,
      ),
      Attr('content', int),
      Attr(
        'owner',
        String,
        canNull: true,
      ),
      Attr('pubkey', String),
      Attr('file', String),
      Attr('sig', String),
      Attr('pid', String),
      Attr('to', String),
      Attr('sync_at', int),
      Attr('created_at', int),
      Attr('expires_at', int),
    ],
  });

  @override
  final icon = IconF(0xe22d);

  final map = MapF<T>();

  List<T> find(MP m) {
    final list = <T>[...map.values];
    if (m case {'since': int time}) {
      time;
    }
    return list;
  }

  bool dontNotify = false;

  Iterable<T> preload(Iterable json) {
    dontNotify = true;
    final re = <T>[];
    for (MP item in json) {
      if (item['id'] is int && !Fractal.map.containsKey(item['id'])) {
        final fractal = put(item);
        re.add(fractal);
      }
    }
    dontNotify = false;
    return re;
  }

  T put(MP item) {
    final pass = item['pass'];
    final fractal = make(item);
    map.complete(fractal.hash, fractal);
    return fractal;
  }

  collect() {
    final res = select();
    preload(res);
  }

  final _consumers = <Function(T)>[];
  consumer(Function(T) cb) {
    _consumers.add(cb);
  }

  consume(T event) {
    for (var c in _consumers) {
      c(event);
    }
  }

  //static final map = <String, EventsCtrl>{};

  @override
  init() async {
    super.init();
    collect();
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
