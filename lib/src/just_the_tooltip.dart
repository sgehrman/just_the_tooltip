import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:just_the_tooltip/src/tooltip_overlay.dart';

class JustTheTooltip extends StatefulWidget {
  final Widget content;

  final Widget child;

  final AxisDirection preferredDirection;

  final Duration fadeInDuration;

  final Duration fadeOutDuration;

  final Curve curve;

  final EdgeInsets padding;

  final EdgeInsets margin;

  final double offset;

  final double elevation;

  final BorderRadiusGeometry borderRadius;

  final double tailLength;

  final double tailBaseWidth;

  /// These directly affect the constraints of the tooltip
  // BoxConstraints constraints;

  final AnimatedTransitionBuilder animatedTransitionBuilder;

  final Color? backgroundColor;

  final TextDirection textDirection;

  static SingleChildRenderObjectWidget defaultAnimatedTransitionBuilder(
    context,
    animation,
    child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  const JustTheTooltip({
    Key? key,
    required this.content,
    required this.child,
    this.preferredDirection = AxisDirection.down,
    this.fadeInDuration = const Duration(milliseconds: 150),
    this.fadeOutDuration = const Duration(milliseconds: 0),
    this.curve = Curves.easeInOut,
    this.padding = const EdgeInsets.all(8.0),
    this.margin = const EdgeInsets.all(8.0),
    this.offset = 0.0,
    this.elevation = 4,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.tailLength = 16.0,
    this.tailBaseWidth = 32.0,
    this.animatedTransitionBuilder = defaultAnimatedTransitionBuilder,
    this.backgroundColor,
    this.textDirection = TextDirection.ltr,
    // this.minWidth,
    // this.minHeight,
    // this.maxWidth,
    // this.maxHeight,
  });

  @override
  _SimpleTooltipState createState() => _SimpleTooltipState();
}

class _SimpleTooltipState extends State<JustTheTooltip>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  late final AnimationController _animationController;
  OverlayEntry? _entry;
  OverlayEntry? _skrim;

  @override
  void initState() {
    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      reverseDuration: widget.fadeOutDuration,
      vsync: this,
    );

    super.initState();
  }

  // @override
  // void didUpdateWidget(covariant JustTheTooltip oldWidget) {
  //   _entry?.markNeedsBuild();
  //   _skrim?.markNeedsBuild();

  //   super.didUpdateWidget(oldWidget);
  // }

  @override
  void dispose() {
    _entry?.remove();
    _skrim?.remove();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _entry == null ? _showTooltip : null,
        child: widget.child,
      ),
    );
  }

  void _hideTooltip({bool immediately = false}) async {
    if (!immediately) {
      await _animationController.reverse();
    }

    _entry?.remove();
    _skrim?.remove();

    setState(() {
      _entry = null;
      _skrim = null;
    });
  }

  void _showTooltip({bool immediately = false}) async {
    _createNewEntries();

    await _animationController.forward();
  }

  void _createNewEntries() {
    assert(_entry == null);
    assert(_skrim == null);
    final box = context.findRenderObject() as RenderBox?;

    if (box == null) {
      throw StateError(
        'Cannot find the box for the given object with context $context',
      );
    }

    final targetSize = box.getDryLayout(BoxConstraints.tightForFinite());
    final target = box.localToGlobal(box.size.center(Offset.zero));
    final offsetToTarget = Offset(
      -target.dx + box.size.width / 2,
      -target.dy + box.size.height / 2,
    );

    final entry = Directionality(
      textDirection: Directionality.of(context),
      child: TooltipOverlay(
        animatedTransitionBuilder: widget.animatedTransitionBuilder,
        child: widget.content,
        padding: widget.padding,
        margin: widget.margin,
        targetSize: targetSize,
        target: target,
        offset: widget.offset,
        preferredDirection: widget.preferredDirection,
        link: _layerLink,
        offsetToTarget: offsetToTarget,
        elevation: widget.elevation,
        borderRadius: widget.borderRadius,
        tailBaseWidth: widget.tailBaseWidth,
        tailLength: widget.tailLength,
        backgroundColor: widget.backgroundColor,
        textDirection: widget.textDirection,
        animation: CurvedAnimation(
          parent: _animationController,
          curve: widget.curve,
        ),
      ),
    );
    final skrim = GestureDetector(
      child: SizedBox.expand(),
      behavior: HitTestBehavior.translucent,
      onTap: _hideTooltip,
    );

    _entry = OverlayEntry(builder: (BuildContext context) => entry);
    _skrim = OverlayEntry(builder: (BuildContext context) => skrim);

    final overlay = Overlay.of(context);

    if (overlay == null) {
      throw StateError('Cannot find the overlay for the context $context');
    }

    setState(() {
      overlay.insert(_skrim!);
      overlay.insert(_entry!, above: _skrim);
    });
  }
}