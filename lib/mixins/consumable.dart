import '../models/index.dart';
import 'hashed.dart';

mixin Consumable<T extends Consumable<dynamic>> on Hashed {
  T? to;

  String? toHash;

  static final map = EventFractal.map;

  consumable(T into) {
    to = into;

    provide(into);
    into.consume(this);
  }

  void consume(T event) {
    /*
    print('consume');
    print(event);
    */
    //notifyListeners();
  }

  provide(T into) {
    /*
    print('provide');
    print(into);
    */
  }

  CatalogFractal? events;
}
