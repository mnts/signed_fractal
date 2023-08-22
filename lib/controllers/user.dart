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
        'public_key',
        String,
      ),
      Attr(
        'private_key',
        String,
        isPrivate: true,
      ),
    ],
  });
}
