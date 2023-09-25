import 'package:fractal/lib.dart';
import 'package:signed_fractal/models/event.dart';
import 'package:signed_fractal/services/sorted.dart';
import '../controllers/node.dart';
import '../security/generator/random_key_pair_generator.dart';
import '../security/key_pair.dart';
import '../services/map.dart';
import '../services/signer.dart';
import '../signed_fractal.dart';
import 'rewriter.dart';

class NodeFractal extends EventFractal implements Rewritable {
  static final controller = NodeCtrl(
    extend: EventFractal.controller,
    make: (d) => switch (d) {
      MP() => NodeFractal.fromMap(d),
      (String s) => NodeFractal(name: s),
      Object() || null => throw ('wrong event type')
    },
  );

  final SortedFrac<EventFractal> sorted;
  sort() {
    write('sorted', sorted.toString());
  }

  @override
  NodeCtrl get ctrl => controller;

  NodeFractal({
    super.expiresAt,
    super.kind,
    super.content,
    super.file,
    super.to,
    required this.name,
    KeyPair? keyPair,
    List<EventFractal>? sub,
  }) : sorted = SortedFrac(sub ?? []) {
    this.keyPair = keyPair ?? RandomKeyPairGenerator().generate();
    construct();
  }

  construct() {}

  @override
  consume(event) {
    if (event case NodeFractal node) {
      sub.complete(node.name, node);
    }
  }

  final sub = MapF<NodeFractal>();

  String name;

  late final KeyPair keyPair;
  static final signer = Signer();
  String sign(String text) => signer.sign(
        privateKey: keyPair.privateKey,
        message: text,
      );

  @override
  get hashData => [...super.hashData];

  NodeFractal.fromMap(MP d)
      : keyPair = KeyPair(
          publicKey: d['public_key'],
          privateKey: d['private_key'],
        ),
        name = d['name'] ?? '',
        sorted = SortedFrac([])
          ..fromString(
            d['sub'],
          ),
        super.fromMap(d) {
    construct();
  }

  MP get _map => {
        'public_key': keyPair.publicKey,
        'private_key': keyPair.privateKey,
        'name': name,
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };

  final title = Writable();

  @override
  onWrite(f) {
    switch (f.attr) {
      case 'title':
        title.value = f;
      case 'sorted':
        sorted.fromString(f.content);
    }
  }
}
