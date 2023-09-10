import 'package:fractal/lib.dart';
import 'package:signed_fractal/models/event.dart';
import '../controllers/node.dart';
import '../security/generator/random_key_pair_generator.dart';
import '../security/key_pair.dart';
import '../services/signer.dart';
import 'rewriter.dart';

class NodeFractal extends EventFractal implements Rewritable {
  static final controller = NodeCtrl(
    extend: EventFractal.controller,
    make: (d) => switch (d) {
      MP() => NodeFractal.fromMap(d),
      Object() || null => throw ('wrong event type')
    },
  );

  @override
  NodeCtrl get ctrl => controller;

  NodeFractal({
    super.expiresAt,
    super.kind,
    super.content,
    super.file,
    super.to,
    KeyPair? keyPair,
  }) {
    this.keyPair = keyPair ?? RandomKeyPairGenerator().generate();
  }

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
        super.fromMap(d);

  MP get _map => {
        'public_key': keyPair.publicKey,
        'private_key': keyPair.privateKey,
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
    }
  }
}
