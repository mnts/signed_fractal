import 'package:fractal/types/icon.dart';
import 'package:fractal_base/models/index.dart';
import '../models/user.dart';
import 'node.dart';

class UserCtrl<T extends UserFractal> extends NodeCtrl<T> {
  UserCtrl({
    super.name = 'user',
    required super.make,
    required super.extend,
    super.attributes = const [
      Attr(
        'eth',
        String,
        canNull: true,
      ),
      Attr(
        'pass',
        String,
      ),
      Attr(
        'private_key',
        String,
        isPrivate: true,
      ),
      Attr(
        'public_key',
        String,
      ),
    ],
  });

  @override
  final icon = IconF(0xe491);
}
