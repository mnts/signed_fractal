import '../signed_fractal.dart';

class GroupCtrl<T extends GroupFractal> extends NodeCtrl<T> {
  GroupCtrl({
    super.name = 'group',
    required super.make,
    required super.extend,
    required super.attributes,
  });

  @override
  final icon = IconF(0xe1ae);
}

class GroupFractal extends NodeFractal {
  static final controller = GroupCtrl(
    extend: NodeFractal.controller,
    make: (d) => switch (d) {
      MP() => GroupFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
    attributes: [
      Attr(
        name: 'group',
        format: 'TEXT',
        canNull: true,
        isImmutable: true,
      ),
    ],
    //indexes: {},
  );

  @override
  GroupCtrl get ctrl => controller;

  String group;

  GroupFractal.fromMap(MP d)
      : group = d['group'],
        super.fromMap(d);

  @override
  operator [](String key) => switch (key) {
        'group' => group,
        _ => super[key],
      };
}
