import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../pizzule_path.dart';

/// 滑动验证码控制器
class SliderController {
  late Offset? Function() create;

  /// 重置验证码
  void reset() {
    create.call();
  }
}

/// 滑动验证码组件
class SliderCaptcha extends StatefulWidget {
  const SliderCaptcha({
    required this.image,
    required this.onConfirm,
    this.title = 'Slide to authenticate',
    this.titleStyle,
    this.captchaSize = 30,
    this.colorBar = Colors.blue,
    this.errorColor = Colors.red,
    this.successColor = Colors.green,
    this.colorCaptChar = Colors.blue,
    this.controller,
    this.borderRadius = 0,
    this.slideContainerDecoration,
    this.icon,
    this.threshold = 10,
    this.loadingColor,
    Key? key,
  })  : assert(0 <= borderRadius && borderRadius <= 10),
        assert(0 <= threshold),
        super(key: key);

  final Widget image;
  final Future<void> Function(bool value)? onConfirm;
  final String title;
  final TextStyle? titleStyle;
  final Color colorBar;
  final Color errorColor;
  final Color successColor;
  final Color colorCaptChar;
  final double captchaSize;
  final Widget? icon;
  final Decoration? slideContainerDecoration;
  final SliderController? controller;
  final double borderRadius;
  final double threshold;
  final Color? loadingColor;

  @override
  State<SliderCaptcha> createState() => _SliderCaptchaState();
}

class _SliderCaptchaState extends State<SliderCaptcha>
    with SingleTickerProviderStateMixin {
  // 常量
  static const double _sliderHeight = 50;
  static const Duration _animationDuration = Duration(milliseconds: 500);
  static const Duration _loadingDelay = Duration(milliseconds: 300);

  // 状态变量
  double _offsetMove = 0;
  double _answerX = 0;
  double _answerY = 0;
  bool _isLock = false;
  bool _isError = false;
  bool _isLoading = false;

  // 控制器
  late SliderController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = SliderController();
    } else {
      _controller = widget.controller!;
    }

    _controller.create = _create;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1, end: 0).animate(_animationController)
      ..addListener(() {
        setState(() {
          _offsetMove = _offsetMove * _animation.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reset();
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _refreshCaptcha();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 创建新的验证码
  Offset? _create() {
    _isError = false;

    // 先获取新的验证码位置
    Offset? offset = _controller.create.call();
    _answerX = offset?.dx ?? 0;
    _answerY = offset?.dy ?? 0;

    // 然后执行动画
    _animationController.forward();

    return offset;
  }

  /// 检查答案是否正确
  Future<void> _checkAnswer() async {
    if (_isLock) return;
    _isLock = true;

    try {
      final bool isCorrect = _offsetMove < _answerX + widget.threshold &&
          _offsetMove > _answerX - widget.threshold;

      setState(() {
        _isError = !isCorrect;
        _isLoading = !isCorrect;
      });

      // 回调通知结果
      await widget.onConfirm?.call(isCorrect);

      // 如果错误，刷新验证码
      if (!isCorrect) {
        await Future.delayed(_loadingDelay);
        _create();

        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _isLock = false;
    }
  }

  /// 处理拖动开始事件
  void _onDragStart(BuildContext context, DragStartDetails start) {
    if (_isLock) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(start.globalPosition);

    setState(() {
      _offsetMove = local.dx - _sliderHeight / 2;
    });
  }

  /// 处理拖动更新事件
  void _onDragUpdate(BuildContext context, DragUpdateDetails update) {
    if (_isLock) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(update.globalPosition);
    final double boxWidth = box.size.width;

    setState(() {
      if (local.dx < 0) {
        _offsetMove = 0;
      } else if (local.dx > boxWidth) {
        _offsetMove = boxWidth - _sliderHeight;
      } else {
        _offsetMove = local.dx - _sliderHeight / 2;
      }
    });
  }

  /// 刷新验证码
  Future<void> _refreshCaptcha() async {
    if (_isLock) return;

    setState(() {
      _isLoading = true;
      _offsetMove = 0;
      _isError = false;
    });

    await Future.delayed(_loadingDelay);
    _create();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCaptchaArea(),
          _buildSliderBar(),
          _buildActionBar(),
        ],
      ),
    );
  }

  /// 构建验证码区域
  Widget _buildCaptchaArea() {
    return Flexible(
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.borderRadius),
          topRight: Radius.circular(widget.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              color: _isError
                  ? widget.errorColor
                  : _isError
                      ? widget.successColor
                      : widget.colorBar,
            ),
            Container(
              color: widget.colorBar,
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Visibility(
                    visible: !_isLoading,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: SliderCaptCha(
                      widget.image,
                      _offsetMove,
                      _answerY,
                      sizeCaptChar: widget.captchaSize,
                      colorCaptChar: widget.colorCaptChar,
                      sliderController: _controller,
                    ),
                  ),
                  if (_isLoading)
                    CupertinoActivityIndicator(color: widget.loadingColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建滑块条
  Widget _buildSliderBar() {
    return Container(
      height: _sliderHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.colorBar,
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Text(
              widget.title,
              style: widget.titleStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            left: _offsetMove,
            top: 0,
            height: _sliderHeight,
            width: _sliderHeight,
            child: GestureDetector(
              onHorizontalDragStart: (detail) => _onDragStart(context, detail),
              onHorizontalDragUpdate: (detail) =>
                  _onDragUpdate(context, detail),
              onHorizontalDragEnd: (_) => _checkAnswer(),
              child: Container(
                height: _sliderHeight,
                width: _sliderHeight,
                margin: const EdgeInsets.all(4),
                decoration: widget.slideContainerDecoration ??
                    BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.white,
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Colors.grey, blurRadius: 4)
                      ],
                    ),
                child: widget.icon ?? const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作栏
  Widget _buildActionBar() {
    return Container(
      height: 40,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(widget.borderRadius),
          bottomRight: Radius.circular(widget.borderRadius),
        ),
        color: widget.colorBar,
      ),
      child: Row(
        children: [
          InkWell(
            child: const Icon(Icons.close),
            onTap: () => widget.onConfirm?.call(false),
          ),
          const SizedBox(width: 8),
          InkWell(
            child: const Icon(Icons.refresh_rounded),
            onTap: _refreshCaptcha,
          ),
        ],
      ),
    );
  }
}

typedef SliderCreate = Offset? Function();

/// 滑动验证码渲染组件
class SliderCaptCha extends SingleChildRenderObjectWidget {
  final Widget image;
  final double offsetX;
  final double offsetY;
  final Color colorCaptChar;
  final double sizeCaptChar;
  final SliderController sliderController;

  const SliderCaptCha(
    this.image,
    this.offsetX,
    this.offsetY, {
    this.sizeCaptChar = 40,
    this.colorCaptChar = Colors.blue,
    required this.sliderController,
    Key? key,
  }) : super(key: key, child: image);

  @override
  RenderObject createRenderObject(BuildContext context) {
    final renderObject = _RenderSliderCaptChar();
    updateRenderObject(context, renderObject);
    sliderController.create = renderObject.create;
    return renderObject;
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderSliderCaptChar renderObject) {
    renderObject
      ..offsetX = offsetX
      ..offsetY = offsetY
      ..colorCaptChar = colorCaptChar
      ..sizeCaptChar = sizeCaptChar;
    super.updateRenderObject(context, renderObject);
  }
}

class _RenderSliderCaptChar extends RenderProxyBox {
  double sizeCaptChar = 40;
  double strokeWidth = 3;
  double offsetX = 0;
  double offsetY = 0;
  double createX = 0;
  double createY = 0;
  Color colorCaptChar = Colors.black;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    // 绘制背景
    context.paintChild(child!, offset);

    // 确保图像已加载
    if (!(child!.size.width > 0 && child!.size.height > 0)) {
      return;
    }

    // 如果还没有创建验证码位置，则不绘制
    if (createX == 0 && createY == 0) return;

    final Paint paint = Paint()
      ..color = colorCaptChar
      ..strokeWidth = strokeWidth;

    // 绘制验证码填充部分
    context.canvas.drawPath(
      getPiecePathCustom(
        size,
        strokeWidth + offset.dx + createX.toDouble(),
        offset.dy + createY.toDouble(),
        sizeCaptChar,
      ),
      paint..style = PaintingStyle.fill,
    );

    // 绘制验证码边框
    context.canvas.drawPath(
      getPiecePathCustom(
        Size(size.width - strokeWidth, size.height - strokeWidth),
        strokeWidth + offset.dx + offsetX,
        offset.dy + createY,
        sizeCaptChar,
      ),
      paint..style = PaintingStyle.stroke,
    );

    // 裁剪并绘制移动部分
    layer = context.pushClipPath(
      needsCompositing,
      Offset(-createX + offsetX + offset.dx + strokeWidth, offset.dy),
      Offset.zero & size,
      getPiecePathCustom(
        size,
        createX,
        createY.toDouble(),
        sizeCaptChar,
      ),
      (context, offset) {
        context.paintChild(child!, offset);
      },
      oldLayer: layer as ClipPathLayer?,
    );
  }

  /// 创建新的验证码位置
  Offset? create() {
    if (size == Size.zero) {
      return null;
    }

    // 随机生成验证码位置
    createX = sizeCaptChar +
        Random().nextInt((size.width - 2.5 * sizeCaptChar).toInt()).toDouble();
    createY = Random().nextInt((size.height - sizeCaptChar).toInt()).toDouble();

    markNeedsPaint();
    return Offset(createX, createY);
  }
}
