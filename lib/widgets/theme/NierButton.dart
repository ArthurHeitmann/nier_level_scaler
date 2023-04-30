

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../stateManagement/dataInstances.dart';
import '../misc/onHoverBuilder.dart';
import 'customTheme.dart';

class NierButton extends StatefulWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isSelected;
  final double? width;

  const NierButton({
    super.key,
    required this.onPressed,
    this.text,
    this.icon,
    this.width,
    this.isSelected = false,
  });

  @override
  State<NierButton> createState() => _NierButtonState();
}

class _NierButtonState extends State<NierButton> {
  final focusNode = FocusNode();
  
  get isDisabled => widget.onPressed == null || statusInfo.isBusy.value;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {});
    });
    statusInfo.isBusy.addListener(_onIsBusyChanged);
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
    statusInfo.isBusy.removeListener(_onIsBusyChanged);
  }

  _onIsBusyChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (!isDisabled && event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
          widget.onPressed!.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: widget.width ?? 180,
        height: 48,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: OnHoverBuilder(
              builder: (context, isHovering) {
                isHovering = isHovering || widget.isSelected || focusNode.hasFocus;
                return Stack(
                children: [
                  Positioned.fill(
                    child: Transform.translate(
                      offset: const Offset(4, 4),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHovering ? 1 : 0,
                        child: Container(
                          color: NierTheme.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isHovering ? NierTheme.dark : NierTheme.grey,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              color: isHovering ? NierTheme.light : NierTheme.dark,
                              child: widget.icon != null ?
                                Icon(
                                  widget.icon,
                                  color: isHovering ? NierTheme.dark : NierTheme.light,
                                  size: 18,
                                ) : null
                            ),
                            if (widget.text != null) ...[
                              const SizedBox(width: 16),
                              Text(
                                widget.text!,
                                style: TextStyle(
                                  color: isHovering ? NierTheme.light : NierTheme.dark,
                                  fontWeight: FontWeight.w500,
                                ),
                                textScaleFactor: 1.1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
              },
            ),
          ),
        ),
      ),
    );
  }
}
