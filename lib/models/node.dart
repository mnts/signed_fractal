import 'package:fractal/lib.dart';
import 'package:signed_fractal/models/event.dart';
import '../controllers/node.dart';
import '../security/key_pair.dart';
import '../services/signer.dart';

class NodeFractal extends EventFractal {
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
    this.keyPair,
  });

  final KeyPair? keyPair;
  static final signer = Signer();
  String sign(String text) => keyPair != null
      ? signer.sign(
          privateKey: keyPair!.privateKey,
          message: text,
        )
      : '';

  @override
  get hashData => [...super.hashData];

  NodeFractal.fromMap(MP d)
      : keyPair = KeyPair(
          publicKey: d['public_key'],
          privateKey: d['private_key'],
        ),
        super.fromMap(d);

  MP get _map => {
        'public_key': keyPair!.publicKey,
        'private_key': keyPair!.privateKey,
      };

  @override
  MP toMap() => {
        ...super.toMap(),
        ..._map,
      };
}
