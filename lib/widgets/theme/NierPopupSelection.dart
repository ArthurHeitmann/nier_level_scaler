
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../misc/SmoothScrollBuilder.dart';
import '../misc/onHoverBuilder.dart';
import 'NierButton.dart';
import 'customTheme.dart';

class NierPopupSelection extends StatefulWidget {
  final List<String> options;
  final void Function(int index) onSelected;
  final int selectedIndex;
  final double? width;
  final double? activeButtonWidth;
  final String Function(int index)? getActiveText;

  const NierPopupSelection({
    super.key,
    required this.options,
    required this.onSelected,
    required this.selectedIndex,
    this.width,
    this.activeButtonWidth,
    this.getActiveText,
  });

  @override
  State<NierPopupSelection> createState() => _NierPopupSelectionState();
}

class _NierPopupSelectionState extends State<NierPopupSelection> {
  final layerLink = LayerLink();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: NierButton(
        text: widget.getActiveText?.call(widget.selectedIndex) ?? widget.options[widget.selectedIndex],
        width: widget.activeButtonWidth,
        onPressed: _onPressed,
      ),
    );
  }

  void _onPressed() {
    showDialog(
      context: context,
      barrierColor: NierTheme.dark.withOpacity(0.333),
      builder: (context) => _SelectionOverlay(
        layerLink: layerLink,
        options: widget.options,
        onSelected: widget.onSelected,
        selectedIndex: widget.selectedIndex,
        width: widget.width,
      )
    );
  }
}

class _SelectionOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final List<String> options;
  final void Function(int) onSelected;
  final int selectedIndex;
  final double width;

  const _SelectionOverlay({
    required this.layerLink,
    required this.options,
    required this.onSelected,
    required this.selectedIndex,
    double? width,
  }) : width = width ?? 200;

  @override
  State<_SelectionOverlay> createState() => _SelectionOverlayState();
}

class _SelectionOverlayState extends State<_SelectionOverlay> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 35.0;
    const decoHeight = 6 * 2 + 2;
    final maxHeight = MediaQuery.of(context).size.height * 0.4;
    final totalHeight = decoHeight * 2 + buttonHeight * widget.options.length;
    final height = min(maxHeight, totalHeight);

    return CompositedTransformFollower(
      link: widget.layerLink,
      targetAnchor: Alignment.topRight,
      followerAnchor: Alignment.topLeft,
      showWhenUnlinked: false,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.width,
                maxHeight: height,
              ),
              child: CustomPaint(
                foregroundPainter: const NierOverlayPainter(vignette: false),
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: Transform.translate(
                          offset: const Offset(4, 4),
                          child: Container(
                            color: NierTheme.dark2,
                          ),
                        )
                    ),
                    Positioned.fill(
                      child: Container(
                        color: NierTheme.light2,
                        width: widget.width,
                        child: _optionalScrollArea(
                          isScrollable: totalHeight > maxHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _makeDecoration(),
                              for (var i = 0; i < widget.options.length; i++)
                                _NierSelectionButton(
                                  text: widget.options[i],
                                  height: buttonHeight,
                                  textScaleFactor: 1,
                                  autofocus: i == widget.selectedIndex,
                                  onPressed: () {
                                    widget.onSelected(i);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              _makeDecoration(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _makeDecoration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
        height: 2,
        color: NierTheme.grey,
      ),
    );
  }

  Widget _optionalScrollArea({ required bool isScrollable, required Column child }) {
    if (!isScrollable)
      return child;
    return SmoothSingleChildScrollView(
      controller: scrollController,
      child: child
    );
  }
}

class _NierSelectionButton extends StatefulWidget {
  final String text;
  final double height;
  final void Function() onPressed;
  final double textScaleFactor;
  final bool autofocus;

  const _NierSelectionButton({
    required this.text,
    required this.height,
    required this.onPressed,
    this.textScaleFactor = 1,
    this.autofocus = false,
  });

  @override
  State<_NierSelectionButton> createState() => _NierSelectionButtonState();
}

class _NierSelectionButtonState extends State<_NierSelectionButton> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnHoverBuilder(
      builder: (context, isHovering) {
        bool isActivated = focusNode.hasFocus || isHovering;
        if (isHovering && !focusNode.hasFocus)
          focusNode.requestFocus();
        return Focus(
          focusNode: focusNode,
          autofocus: widget.autofocus,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
              widget.onPressed.call();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: widget.height,
              color: isActivated ? NierTheme.dark : Colors.transparent,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.text,
                    textScaleFactor: widget.textScaleFactor,
                    maxLines: 1,
                    style: TextStyle(
                      color: isActivated ? NierTheme.light : NierTheme.dark,
                    ),
                  ),
                ),
              )
            ),
          )
        );
      },
    );
  }
}


