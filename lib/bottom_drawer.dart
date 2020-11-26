import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BottomDrawerController {
  void open() {
    _handler?.call(true);
  }

  void close() {
    _handler?.call(false);
  }

  void Function(bool open) _handler;
}

class BottomDrawer extends StatefulWidget {
  BottomDrawer({
    Key key,
    @required this.header,
    @required this.body,
    @required this.headerHeight,
    @required this.drawerHeight,
    this.color = Colors.white,
    this.cornerRadius = 12,
    this.duration = const Duration(milliseconds: 250),
    this.activeByDrawer = true,
    this.controller,
    this.callback,
  });

  @override
  _BottomDrawerState createState() => _BottomDrawerState();

  final Widget header;
  final Widget body;

  final double headerHeight;
  final double drawerHeight;

  final Color color;
  final double cornerRadius;
  final Duration duration;

  final bool activeByDrawer;

  final BottomDrawerController controller;

  final Function(bool opened) callback;
}

class _BottomDrawerState extends State<BottomDrawer> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    animationController = AnimationController(vsync: this, duration: widget.duration);

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
        gestures: {VerticalDragGestureRecognizer: getRecognizer()},
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
    switch (notification.runtimeType) {
      case ScrollStartNotification:
        ScrollStartNotification scrollNotification = notification;
        ScrollMetrics metrics = scrollNotification.metrics;
        scrollOffset = metrics.pixels;
        scrollAtEdge = metrics.atEdge;
        return true;
      case ScrollUpdateNotification:
        ScrollUpdateNotification scrollNotification = notification;
        ScrollMetrics metrics = scrollNotification.metrics;
        double pixels = metrics.pixels;
        double flag = pixels - scrollOffset;
        if (flag > 0 && !opened && widget.activeByDrawer) {
          open();
        }
        return true;
      case ScrollEndNotification:
        return true;
      case OverscrollNotification:
        OverscrollNotification scrollNotification = notification;
        ScrollMetrics metrics = scrollNotification.metrics;
        double pixels = metrics.pixels;
        double flag = pixels - scrollOffset;
        if (scrollOffset == 0.0 && flag == 0.0 && scrollAtEdge && opened && widget.activeByDrawer) {
          close();
        }
        return true;
    }
    return false;
  }

  void open([bool callback]) {
    if (!opened) {
      double end = 0;
      double start = offset;
      slide(start, end, callback ?? true);
    }
  }

  void close([bool callback]) {
    if (opened) {
      double end = drawerHeight - headerHeight;
      double start = offset;
      slide(start, end, callback ?? true);
    }
  }

  void slide(double start, double end, bool callback) {
    opened = end == 0.0;

    if (callback) widget.callback?.call(opened);

    CurvedAnimation curve = new CurvedAnimation(parent: animationController, curve: Curves.easeOut);

    animation = Tween(begin: start, end: end).animate(curve)
      ..addListener(() {
        setState(() {
          offset = animation.value;
        });
      });

    animationController.reset();
    animationController.forward();
  }

  bool opened = false;

  double headerHeight;
  double drawerHeight;

  double offset;

  double lastDrag;
  double lastDragOffset;

  double scrollOffset;
  bool scrollAtEdge = false;

  Animation<double> animation;
  AnimationController animationController;
}
