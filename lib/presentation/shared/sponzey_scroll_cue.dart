import 'package:flutter/material.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';

class SponzeyScrollCue extends StatefulWidget {
  const SponzeyScrollCue({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<SponzeyScrollCue> createState() => _SponzeyScrollCueState();
}

class _SponzeyScrollCueState extends State<SponzeyScrollCue> {
  static const double _scrollbarGap = 8;
  bool _showBottomCue = false;
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateCueVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCueVisibility());
  }

  @override
  void didUpdateWidget(covariant SponzeyScrollCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_updateCueVisibility);
    widget.controller.addListener(_updateCueVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCueVisibility());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCueVisibility);
    super.dispose();
  }

  void _updateCueVisibility() {
    if (!widget.controller.hasClients) {
      if (_showBottomCue || _canScroll) {
        setState(() {
          _showBottomCue = false;
          _canScroll = false;
        });
      }
      return;
    }

    final position = widget.controller.position;
    final canScroll = position.maxScrollExtent > 8;
    final shouldShow =
        canScroll && position.pixels < position.maxScrollExtent - 8;

    if (shouldShow == _showBottomCue && canScroll == _canScroll) {
      return;
    }

    setState(() {
      _canScroll = canScroll;
      _showBottomCue = shouldShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scrollbarThickness = _resolveScrollbarThickness(context);
    final reservedRightSpace = _canScroll
        ? scrollbarThickness + _scrollbarGap
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: EdgeInsets.only(right: reservedRightSpace),
          child: Scrollbar(
            controller: widget.controller,
            thumbVisibility: _canScroll,
            trackVisibility: _canScroll,
            interactive: true,
            child: widget.child,
          ),
        ),
        Positioned(
          left: 0,
          right: reservedRightSpace,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _showBottomCue ? 1 : 0,
              child: Container(
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00FFFEF2), AppColors.brandYellowMist],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scroll',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _resolveScrollbarThickness(BuildContext context) {
    final theme = ScrollbarTheme.of(context);
    final thickness = theme.thickness?.resolve(const <WidgetState>{});
    if (thickness != null && thickness > 0) {
      return thickness;
    }
    return 10;
  }
}
