import 'package:flutter/material.dart';
import 'package:slider_captcha/slider_captcha.dart';

class SliderCaptchaClientVerify extends StatefulWidget {
  const SliderCaptchaClientVerify({Key? key, required this.title})
      : super(key: key);
  final String title;

  @override
  State<SliderCaptchaClientVerify> createState() =>
      _SliderCaptchaClientVerifyState();
}

class _SliderCaptchaClientVerifyState extends State<SliderCaptchaClientVerify> {
  final SliderController controller = SliderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber,
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SliderCaptcha(
            controller: controller,
            image: Image.asset(
              'assets/image.jpeg',
              fit: BoxFit.fitWidth,
            ),
            colorBar: Colors.blue,
            colorCaptChar: Colors.blue,
            title: "滑动验证",
            captchaSize: 30,
            borderRadius: 5,
            onConfirm: (value) async {
              debugPrint(value.toString());
              // if (value == false) {
              return await Future.delayed(const Duration(seconds: 2)).then(
                (value) {
                  controller.create.call();
                },
              );
              // }
            },
          ),
        ),
      ),
    );
  }
}
