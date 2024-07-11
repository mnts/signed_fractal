import 'package:fractal_base/fractals/device.dart';

import '../controllers/events.dart';
import '../signed_fractal.dart';
import 'event.dart';

class InteractionCtrl<T extends InteractionFractal> extends NodeCtrl<T> {
  InteractionCtrl({
    super.name = 'interaction',
    required super.make,
    required super.extend,
    super.attributes = const <Attr>[],
  });

  @override
  final icon = IconF(0xf06cc);
}

mixin InteractiveFractal on EventFractal {
  //InteractionFractal? _myInteraction;

  final interactions = MapF<InteractionFractal>();
  interactiveFractal() {}

  addInteraction(InteractionFractal f) {
    /*
    if (f.own) {
      _myInteraction = f;
    }

    f.ownerC.future.then((owner) {
      if (owner == null) return;
      interactions.complete(owner.hash, f);
    });
    */
  }

  InteractionFractal get myInteraction {
    //if (_myInteraction != null) return _myInteraction!;
    final user = UserFractal.active.value ?? DeviceFractal.my;
    //if (user == null) throw 'Not signed in';
    return interactions.map[user.hash] ??
        InteractionFractal(
          to: this,
        );
    //..synch();
    //_myInteraction = interaction;

    /*
    final filter = CatalogFractal(
      filter: {'to': hash},
    )
      ..createdAt = 2
      ..synch();
    */

    //return interaction;
  }
}

class InteractionFractal extends NodeFractal {
  static final controller = InteractionCtrl(
    extend: NodeFractal.controller,
    make: (d) => switch (d) {
      MP() => InteractionFractal.fromMap(d),
      _ => throw ('wrong')
    },
  );

  @override
  InteractionCtrl get ctrl => controller;

  @override
  List get hashData => [0, pubkey, to?.ref ?? '', type];

  InteractionFractal({
    super.to,
  }) {}

  @override
  provide(into) {
    if (into case InteractiveFractal re) re.addInteraction(this);
    super.provide(into);
  }

  InteractionFractal.fromMap(MP d) : super.fromMap(d) {}

  @override
  MP toMap() => {
        ...super.toMap(),
      };

  @override
  onWrite(f) {
    return switch (f.attr) {
      _ => super.onWrite(f),
    };
  }
}
