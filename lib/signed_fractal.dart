import 'package:fractal/lib.dart';

import 'models/group.dart';
import 'models/index.dart';
import 'fr.dart';
export 'models/index.dart';
export 'mixins/index.dart';
export 'controllers/index.dart';
export 'services/index.dart';
export 'security/index.dart';
export 'package:fractal/lib.dart';
export 'package:frac/frac.dart';
export 'package:fractals2d/models/canvas.dart';

class SignedFractal {
  static final ctrls = <FractalCtrl>[
    Fractal.controller,
    EventFractal.controller,
    PostFractal.controller,
    WriterFractal.controller,
    NodeFractal.controller,
    FilterFractal.controller,
    CatalogFractal.controller,
    InteractionFractal.controller,
    ConnectionFractal.controller,
    NetworkFractal.controller,
  ];

  static Future<int> init() async {
    for (final el in ctrls) {
      await el.init();
    }
    await UserFractal.init();

    return 1;
  }
}
