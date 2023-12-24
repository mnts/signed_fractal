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
}

mixin InteractiveFractal on EventFractal {
  InteractionFractal? myInteraction;

  final interactions = MapF<InteractionFractal>();
  interactiveFractal() {}

  addInteraction(InteractionFractal f) {
    if (f.own) {
      myInteraction = f;
    }

    f.ownerC.future.then((owner) {
      if (owner == null) return;
      interactions.complete(owner.hash, f);
    });
  }

  InteractionFractal interact() {
    final user = UserFractal.active.value;
    if (user == null) throw 'Not signed in';
    final interaction =
        interactions.map[user.hash] ?? InteractionFractal(to: this)
          ..synch();
    myInteraction = interaction;

    return interaction;
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
  List get hashData => [0, pubkey, toHash ?? to?.hash ?? '', type];

  InteractionFractal({
    super.to,
  });

  @override
  provide(into) {
    if (into case InteractiveFractal re) re.addInteraction(this);
  }

  InteractionFractal.fromMap(MP d) : super.fromMap(d) {}

  @override
  MP toMap() => {
        ...super.toMap(),
      };

  @override
  onWrite(f) {
    switch (f.attr) {
      default:
        super.onWrite(f);
    }
  }
}
