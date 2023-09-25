import 'dart:convert';
import 'dart:io';
import 'package:app_fractal/index.dart';
import 'package:fractal/utils/random.dart';
import 'package:fractal_socket/index.dart';
import 'package:signed_fractal/signed_fractal.dart';

class ConsoleF {
  ConsoleF() {
    EventFractal.map.listen(announce);
  }

  final app = AppFractal(
    domain: 'co.slyverse.com',
    title: 'Slyverse console',
    name: "sly_console",
  )..complete();

  /*
  Black:   \x1B[30m
  Red:     \x1B[31m
  Green:   \x1B[32m
  Yellow:  \x1B[33m
  Blue:    \x1B[34m
  Magenta: \x1B[35m
  Cyan:    \x1B[36m
  White:   \x1B[37m
  Reset:   \x1B[0m
  */

  announce(EventFractal ev) async {
    //if (name == ev.pubkey) return;
    if (ev.type != 'event') return;

    if ((ev.toHash ?? '') != (event?.hash ?? '')) return;
    print('\x1B[36m ${ev.createdAt} \x1B[35m #${ev.hash}\x1B[0m');
    ev.ownerC.future.then((_) {
      print('\x1B[33m ${ev.owner?.name ?? 'anon!'}:\x1B[0m ${ev.content}');
    });
  }

  EventFractal? event;
  subscribe(String hash) async {
    //EventFractal.controller.unListen(announce);
    event = await EventFractal.map.request(hash);
    //event.consume(event);
  }

  requestLogin(UserFractal user) {
    print('Enter password for #${user.hash} to login');
    final password = stdin.readLineSync() ?? '';

    if (user.auth(password)) {
      UserFractal.activate(user);
      print('You logged in');
    } else {
      print('Wrong password');
      requestLogin(user);
      return;
    }
  }

  requestRegister(String name) {
    final password = stdin.readLineSync() ?? '';
    if (password.length < 5) {
      print('too sort');
      requestRegister(name);
    }

    final user = UserFractal(
      //eth: address,
      name: name,
      password: password,
    );
    user.synch();
    UserFractal.activate(user);
  }

  requestRoom([String? name]) {
    name ??= stdin.readLineSync() ?? '';

    if (name.length < 5) {
      print('too sort name, enter new name');
      requestRoom();
    }

    event = app.sub.map[name];
    if (event == null) {
      event = NodeFractal(
        name: name,
        to: app,
      )..synch();
      print('Room $name was created #${event!.hash}');
    }
  }
}

void main(List<String> args) async {
  final dir = Directory.current.path;
  print(dir);

  FileF.path = './';
  await DBF.initiate();
  await SignedFractal.init();

  final co = ConsoleF();

  final socketId = DBF.main['socket'] ??= getRandomString(8);
  FileF.isSecure = true;
  FileF.host = 'co.slyverse.com';
  final socket = FClient(
    name: socketId,
  );

  //socket.find();

  print('App hash ${co.app.hash}');

  print('''\x1B[36m 
 _______  ___      __   __  __   __  _______  ______    _______  _______ 
|       ||   |    |  | |  ||  | |  ||       ||    _ |  |       ||       |
|  _____||   |    |  |_|  ||  |_|  ||    ___||   | ||  |  _____||    ___|
| |_____ |   |    |       ||       ||   |___ |   |_||_ | |_____ |   |___ 
|_____  ||   |___ |_     _||       ||    ___||    __  ||_____  ||    ___|
 _____| ||       |  |   |   |     | |   |___ |   |  | | _____| ||   |___ 
|_______||_______|  |___|    |___|  |_______||___|  |_||_______||_______|
''');

  //print('\x1B[34m Connecting #${FileF.host}');
  await socket.connect();

  print('Enter your username:');
  final name = stdin.readLineSync()!;

  try {
    var user = UserFractal.map.list.firstWhere(
      (u) => u.name == name,
    );
    co.requestLogin(user);
  } catch (e) {
    print('Username is available, enter password to register');
    co.requestRegister(name);
  }

  final m = {
    'cmd': 'find',
    'since': 0,
  };

  print('Chat started, write messages\x1B[0m');

  socket.sink(m);

  stdin.transform(utf8.decoder).listen((d) {
//    stdin.transform(utf8.decoder(d));
    if (d.isEmpty) return;
    final cmd = d.substring(0, d.length - 1).trim();
    if (cmd.isEmpty) return;
    if (cmd.startsWith('#')) {
      final hash = cmd.substring(1);

      if (hash.length > 2 && hash.length < 20) {
        co.requestRoom(hash);
      } else {
        co.subscribe(hash);
      }

      print('\x1B[33m subscribed to #$hash\x1B[0m');

      return;
    }

    if (cmd.startsWith('/')) {
      final act = cmd.substring(1).trim();

      if (act == "users") {
        print(
          UserFractal.map.list
              .map(
                (u) => u.name,
              )
              .join(','),
        );
      }
      if (act == 'topics') {
        print(
          co.app.sub.list
              .map(
                (n) => n.name,
              )
              .join(','),
        );
      }
      return;
    }

    final ev = EventFractal(
      content: cmd,
      pubkey: name,
      to: co.event,
    );
    ev.synch();
  });
}
