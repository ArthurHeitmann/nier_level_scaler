

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../stateManagement/dataInstances.dart';
import '../../utils/utils.dart';
import '../misc/onHoverBuilder.dart';
import 'cursorIcon.dart';
import 'customTheme.dart';

class NierButtonFancy extends StatefulWidget {
  final String text;
  final String? rightText;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isSelected;
  final double? height;
  final double? width;
  final double textScaleFactor;

  const NierButtonFancy({
    super.key,
    required this.onPressed,
    required this.text,
    this.rightText,
    this.icon,
    this.height,
    this.width,
    this.textScaleFactor = 1.0,
    this.isSelected = false,
  });

  @override
  State<NierButtonFancy> createState() => _NierButtonFancyState();
}

class _NierButtonFancyState extends State<NierButtonFancy> {
  final focusNode = FocusNode();
  final layerLink = LayerLink();
  OverlayEntry? overlayEntry;

  bool get isDisabled => widget.onPressed == null || statusInfo.isBusy.value;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {});
    });
  }

  void onHoverEnter() async {
    final overlayState = Overlay.of(context);
    await waitForNextFrame();

    overlayEntry = OverlayEntry(
      builder: (context) => CursorIcon(
        layerLink: layerLink,
      ),
    );
    overlayState.insert(overlayEntry!);
  }

  void onHoverExit() async {
    await waitForNextFrame();
    overlayEntry?.remove();
    overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    const padding = 7.0;
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (!isDisabled && event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
          widget.onPressed!.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: CompositedTransformTarget(
          link: layerLink,
          child: SizedBox(
            width: widget.width ?? 180,
            height: widget.height ?? 48 + padding * 2,
            child: GestureDetector(
              onTap: widget.onPressed,
              child: OnHoverBuilder(
                builder: (context, isHovering) {
                  isHovering = isHovering || widget.isSelected || focusNode.hasFocus;

                  if (isHovering && overlayEntry == null)
                    onHoverEnter();
                  else if (!isHovering && overlayEntry != null)
                    onHoverExit();

                  return Stack(
                    clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: padding,
                      bottom: padding,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: isHovering ? NierTheme.dark : Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24 * widget.textScaleFactor,
                                height: 24 * widget.textScaleFactor,
                                color: isHovering ? NierTheme.light : NierTheme.dark,
                                child: widget.icon != null ?
                                  Icon(
                                    widget.icon,
                                    color: isHovering ? NierTheme.dark : NierTheme.light,
                                    size: 18,
                                  ) : null
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.text,
                                  style: TextStyle(
                                    color: isHovering ? NierTheme.light : NierTheme.dark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textScaleFactor: 1.1 * widget.textScaleFactor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.rightText != null)
                                Text(
                                  widget.rightText!,
                                  style: TextStyle(
                                    color: isHovering ? NierTheme.light : NierTheme.dark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textScaleFactor: 1.1 * widget.textScaleFactor,
                                ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 2.5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: isHovering ? NierTheme.dark : Colors.transparent,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 2.5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: isHovering ? NierTheme.dark : Colors.transparent,
                      ),
                    ),
                  ],
                );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
