import '../key_pair.dart';

/// A generator that generates key pairs.
abstract class KeyPairGenerator<T> {
  const KeyPairGenerator._();

  KeyPair generate({T params});
}
