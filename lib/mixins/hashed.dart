import '../models/event.dart';
import 'package:dart_bs58check/dart_bs58check.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

mixin Hashed {
  String hash = '';
  bool get isSaved => hash.isNotEmpty;

  List get hashData => [];

  doHash() {
    return hash = makeHash(hashData);
  }

  static String makeHash(hashData) {
    String serializedEvent = json.encode([
      ...hashData.map((d) => d ?? ''),
    ]);
    final h = Uint8List.fromList(
      sha256.convert(utf8.encode(serializedEvent)).bytes,
    );
    return bs58check.encode(h);
  }

  signa() {
    if (hash.isEmpty) {
      throw Exception(
        'event is not complete for signature',
      );
    }
  }
}
