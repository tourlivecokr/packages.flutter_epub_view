import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelManager {
  static Mixpanel? instance;

  static Future<void> init() async {
    instance ??= await Mixpanel.init("1dac22d67390b7835e2a855fc1aebac4",
        optOutTrackingDefault: false, trackAutomaticEvents: true);
  }

  static int? setId;

  static logoutUser() {
    if (setId != null) {
      instance?.reset();
    }
  }
}
