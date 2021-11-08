import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Created by GP
/// 2020/11/25.

/// drawer controller.
class BottomDrawerController {
  /// open drawer.
  void open() {
    _handler?.call(true);
  }

  /// close drawer.
  void close() {
    _handler?.call(false);
  }

  void Function(bool open)? _handler;
}

/// bottom drawer.
class BottomDrawer extends StatefulWidget {
  BottomDrawer({
    Key? key,
    required this.header,
    required this.body,
    required this.headerHeight,
    required this.drawerHeight,
    this.color = Colors.white,
    this.cornerRadius = 12,
    this.boxShadow = const [],
    this.duration = const Duration(milliseconds: 250),
    this.followTheBody = true,
    this.controller,
    this.callback,
  });

  @override
  _BottomDrawerState createState() => _BottomDrawerState();

  /// drawer header.
  final Widget header;

  /// drawer body.
  final Widget body;

  /// drawer header height.
  final double headerHeight;

  /// drawer total height.
  final double drawerHeight;

  /// drawer color.
  final Color color;

  /// drawer corner radius.
  final double cornerRadius;

  /// drawer animation duration.
  final Duration duration;

  /// drawer box shadow.
  final List<BoxShadow> boxShadow;

  ///If configured as true,
  ///When the drawer is open, the body slides to the top, and then slides down, the drawer will automatically close.
  ///When the drawer is closed, the body slides up and the drawer will automatically open.
  final bool followTheBody;

  /// drawer controller.
  final BottomDrawerController? controller;

  /// drawer status callback.
  final Function(bool opened)? callback;
}

class _BottomDrawerState extends State<BottomDrawer> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    widget.controller?._handler = (open) {
      if (open)
        this.open(false);
      else
        this.close(false);
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      headerHeight = widget.headerHeight;
      drawerHeight = widget.drawerHeight;
      offset = drawerHeight - headerHeight;
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.bottomCenter,
      child: buildSlider(),
    );
  }

  Widget buildSlider() {
    offset = offset.clamp(0.0, drawerHeight - headerHeight);
    return Transform.translate(
      offset: Offset(0.0, offset),
      child: RawGestureDetector(
        gestures: {
          VerticalDragGestureRecognizer: getRecognizer(),
        },
        child: buildDrawer(),
      ),
    );
  }

  GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer> getRecognizer() {
    return GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
      _buildVerticalDragGestureRecognizerConstructor,
      _buildVerticalDragGestureRecognizerInitializer,
    );
  }

  VerticalDragGestureRecognizer _buildVerticalDragGestureRecognizerConstructor() {
    return VerticalDragGestureRecognizer();
  }

  void _buildVerticalDragGestureRecognizerInitializer(VerticalDragGestureRecognizer gestureRecognizer) {
    gestureRecognizer
      ..onStart = onDragStart
      ..onUpdate = onDragUpdate
      ..onEnd = onDragEnd;
  }

  void onDragStart(DragStartDetails details) {
    lastDrag = details.globalPosition.dy;
  }

  void onDragUpdate(DragUpdateDetails details) {
    lastDragOffset = details.globalPosition.dy - lastDrag;
    offset = offset + details.delta.dy;
    lastDrag = details.globalPosition.dy;
    setState(() {});
  }

  void onDragEnd(DragEndDetails details) {
    if (lastDragOffset < 0) {
      open();
    } else {
      close();
    }
  }

  Widget buildDrawer() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: drawerHeight,
        minHeight: headerHeight,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.cornerRadius),
            topRight: Radius.circular(widget.cornerRadius),
          ),
          boxShadow: widget.boxShadow,
        ),
        child: Column(
          children: [
            widget.header,
            Expanded(
              child: NotificationListener(
                onNotification: (Notification notification) => handleScrollNotification(notification),
                child: widget.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool handleScrollNotification(Notification notification) {
    if (widget.followTheBody)
      switch (notification.runtimeType) {
        case ScrollStartNotification:
          ScrollStartNotification scrollNotification = notification as ScrollStartNotification;
          ScrollMetrics metrics = scrollNotification.metrics;
          scrollOffset = metrics.pixels;
          scrollAtEdge = metrics.atEdge;
          return true;
        case ScrollUpdateNotification:
          ScrollUpdateNotification scrollNotification = notification as ScrollUpdateNotification;
          ScrollMetrics metrics = scrollNotification.metrics;
          double pixels = metrics.pixels;
          double flag = pixels - scrollOffset;
          if (flag > 0 && !opened) open();
          return true;
        case ScrollEndNotification:
          return true;
        case OverscrollNotification:
          OverscrollNotification scrollNotification = notification as OverscrollNotification;
          ScrollMetrics metrics = scrollNotification.metrics;
          double pixels = metrics.pixels;
          double flag = pixels - scrollOffset;
          if (scrollOffset == 0.0 && flag == 0.0 && scrollAtEdge && opened) close();
          return true;
      }
    return false;
  }

  void open([bool? callback]) {
    if (!opened) {
      double end = 0;
      double? start = offset;
      slide(start, end, callback ?? true);
    }
  }

  void close([bool? callback]) {
    if (opened) {
      double end = drawerHeight - headerHeight;
      double? start = offset;
      slide(start, end, callback ?? true);
    }
  }

  void slide(double? start, double end, bool callback) {
    opened = end == 0.0;

    if (callback) widget.callback?.call(opened);

    CurvedAnimation curve = new CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    animation = Tween(
      begin: start,
      end: end,
    ).animate(curve)
      ..addListener(() {
        setState(() {
          offset = animation.value;
        });
      });

    animationController.reset();
    animationController.forward();
  }

  bool opened = false;

  late double headerHeight;
  late double drawerHeight;

  double offset = 0.0;

  late double lastDrag;
  late double lastDragOffset;

  double scrollOffset = 0.0;
  bool scrollAtEdge = false;

  late Animation<double> animation;
  late AnimationController animationController;
}
