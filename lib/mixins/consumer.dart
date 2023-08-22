import '../models/event.dart';

mixin ConsumerMix on EventFractal {
  consume(EventFractal event) {}
}
