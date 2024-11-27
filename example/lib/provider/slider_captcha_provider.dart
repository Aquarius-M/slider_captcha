import 'package:example/service/slider_captcha_service.dart';
import 'package:flutter/cupertino.dart';

import '../model/captcha_model.dart';

class SliderCaptchaProvider extends ChangeNotifier {
  final _service = SliderCaptchaService();
  late CaptchaModel? captcha;

  bool isLoading = false;

  SliderCaptchaProvider() {
    getCaptchar();
  }

  Future<void> getCaptchar() async {
    isLoading = true;
    notifyListeners();
    captcha = await _service.getCaptcha();
    isLoading = false;
    notifyListeners();
  }
}
