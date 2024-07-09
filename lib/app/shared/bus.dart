import 'package:event_bus/event_bus.dart';

class SettingEvent {
  bool nsfw;

  SettingEvent({this.nsfw = false});
}

EventBus $bus = EventBus();
