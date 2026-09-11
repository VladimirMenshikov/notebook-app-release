import 'package:flutter/material.dart';

/// Прокручиваемая область с постоянно видимой линейкой прокрутки.
///
/// На Android стандартный [Scrollbar] показывается только во время активного
/// скролла и быстро исчезает, из-за чего непонятно, что текст не помещается
/// на экран. Здесь линейка закреплена ([thumbVisibility]), чтобы длинный
/// текст (описания, заметки, ответы) было видно как прокручиваемый.
class AppScrollbar extends StatefulWidget {
  final Widget child;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;

  const AppScrollbar({
    super.key,
    required this.child,
    this.scrollDirection = Axis.vertical,
    this.padding,
  });

  @override
  State<AppScrollbar> createState() => _AppScrollbarState();
}

class _AppScrollbarState extends State<AppScrollbar> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}
