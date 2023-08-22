import 'package:fractal/lib.dart';
import '../controllers/user.dart';
import 'node.dart';

class UserFractal extends NodeFractal {
  static UserFractal? current;
  static final controller = UserCtrl(
    make: (d) => switch (d) {
      MP() => UserFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
    extend: NodeFractal.controller,
  );

  @override
  UserCtrl get ctrl => controller;

  UserFractal({
    super.id,
    super.hash,
    super.pubkey,
    super.createdAt,
    super.syncAt,
    super.expiresAt,
    super.kind,
    super.content,
    super.file,
    super.sig,
    super.name,
    super.to,
  });

  @override
  get hashData => [
        ...super.hashData,
      ];

  UserFractal.fromMap(MP d) : super.fromMap(d);

  MP get _map => {};

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };
}
