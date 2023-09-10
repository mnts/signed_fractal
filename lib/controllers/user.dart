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
        'name',
        String,
        canNull: true,
        isUnique: true,
      ),
      Attr(
        'pass',
        String,
      ),
    ],
  });
}
