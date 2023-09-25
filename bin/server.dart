import 'dart:io';
import 'package:fractal_server/fractal_server.dart';
import 'package:fractal_socket/socket.dart';
import 'package:signed_fractal/signed_fractal.dart';

void main(List<String> args) async {
  FileF.path = './';
  await DBF.initiate();
  await SignedFractal.init();

  final dir = Directory.current.path;
  print(dir);

  FServer(
    port: args.isNotEmpty ? int.parse(args[0]) : 8800,
    buildSocket: (name) => FSocket(
      name: name,
    ),
  );
}
