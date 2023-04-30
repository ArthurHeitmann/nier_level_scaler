
import 'dart:math';

import 'package:flutter/material.dart';

import '../../stateManagement/dataInstances.dart';
import '../../stateManagement/stages/editLevels.dart';
import '../../stateManagement/stages/export.dart';
import '../../stateManagement/stages/setup.dart';
import '../../stateManagement/stages/stages.dart';
import '../misc/ChangeNotifierWidget.dart';
import '../misc/RowSeparated.dart';
import '../misc/SmoothScrollBuilder.dart';
import '../misc/debugContainer.dart';
import '../theme/NierButton.dart';
import '../theme/NierSavingIndicator.dart';
import '../theme/customTheme.dart';
import 'levelsEditor.dart';
import 'levelsTopEditor.dart';
import 'setupEditor.dart';

class MainLayout extends StatefulWidget {
  final Stages stages;
  
  const MainLayout({ super.key, required this.stages });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final tabsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.stages.currentStage.addListener(_onStateChanged);
    for (final stage in widget.stages.stages) {
      stage.isValid.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.stages.currentStage.removeListener(_onStateChanged);
    for (final stage in widget.stages.stages) {
      stage.isValid.removeListener(_onStateChanged);
    }
  }

  _onStateChanged() {
    setState(() {});
  }

  Widget _makeEditorFrom(Stage stage) {
    switch (stage.type) {
      case StageType.setup:
        return PathsEditor(stage: stage as StageSetup);
      case StageType.editLevels:
        return LevelsEditor(stage: stage as StageEditLevels);
      case StageType.export:
        return const Placeholder();
    }
  }

  Widget _makeTopEditorFrom(Stage stage) {
    switch (stage.type) {
      case StageType.setup:
      case StageType.export:
        return const SizedBox.shrink();
      case StageType.editLevels:
        return LevelsTopEditor(stage: stage as StageEditLevels);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // top deco row
        Positioned(
          top: 70,
          left: 0,
          right: 0,
          height: 28,
          child: CustomPaint(
            painter: _DecoRowPainter(),
          ),
        ),
        // bottom deco row
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          height: 28,
          child: CustomPaint(
            painter: _DecoRowPainter(),
          ),
        ),
        // content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // tabs
                RowSeparated(
                  separatorWidth: 40,
                  children: [
                    for (var i = 0; i < widget.stages.stages.length; i++)
                      if (widget.stages.stages[i] is! SingleActionStage)
                        NierButton(
                          text: widget.stages.stages[i].type.name,
                          width: 215,
                          onPressed: i == 0 || widget.stages.stages[i - 1].isValid.value ?
                            () => setState(() => widget.stages.currentStage.value = i)
                            : null,
                          isSelected: widget.stages.currentStage.value == i,
                        ),
                    const Spacer(),
                    for (var actionStage in widget.stages.stages.whereType<SingleActionStage>())
                      NierButton(
                        width: 215,
                        text: actionStage.type.name,
                        icon: actionStage.actionIcon,
                        onPressed: actionStage.isValid.value ? actionStage.action : null,
                      )
                  ],
                ),
                const SizedBox(height: 30),
                // title
                Row(
                  children: [
                    Stack(
                      children: [
                        Text(
                          widget.stages.stages[widget.stages.currentStage.value].type.name,
                          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                            fontSize: 64,
                            letterSpacing: 8
                          )
                        ),
                        Transform.translate(
                          offset: const Offset(8, 10),
                          child: Text(
                            widget.stages.stages[widget.stages.currentStage.value].type.name,
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              fontSize: 64,
                              letterSpacing: 8,
                              color: NierTheme.dark.withOpacity(0.25),
                            )
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, left: 16),
                        child: _makeTopEditorFrom(widget.stages.stages[widget.stages.currentStage.value]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // editor
                Expanded(
                  child: IndexedStack(
                    index: widget.stages.currentStage.value,
                    children: [
                      for (var i = 0; i < widget.stages.stages.length; i++)
                        _makeEditorFrom(widget.stages.stages[i]),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        // saving indicator
        Positioned(
          top: 12,
          right: 28,
          child: ChangeNotifierBuilder(
            notifier: statusInfo.isBusy,
            builder: (context) => statusInfo.isBusy.value
              ? const NierSavingIndicator()
              : const SizedBox.shrink(),
          ),
        )
      ],
    );
  }
}

class _DecoRowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // draw full width line
    // underneath Repeating patterns of 3 dots arranged in triangle
    // separated by a small rectangle

    var linePaint = Paint()
      ..color = NierTheme.dark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    var shapePaint = Paint()
      ..color = NierTheme.dark
      ..style = PaintingStyle.fill;
    
    // draw full width line
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      linePaint
    );

    const edgePadding = 72.0;
    const patternMaxWidth = 80.0;
    var patternsCount = (size.width - edgePadding * 2) ~/ patternMaxWidth;
    var patternWidth = (size.width - edgePadding * 2) / patternsCount;
    const dotRadius = 3.0;
    const triangleSize = 16.0;
    const dotXDist = triangleSize / 2;
    final dotYDist = sqrt(pow(triangleSize, 2) - pow(dotXDist, 2));
    const dotYOff = 10.0;

    for (var i = 0; i < patternsCount; i++) {
      double x = edgePadding + patternWidth * i;
      // leading rectangle
      canvas.drawRect(
        Rect.fromLTWH(x - 6, 0, 12, 6),
        shapePaint
      );
      // rectangle after last pattern
      if (i == patternsCount - 1) {
        canvas.drawRect(
          Rect.fromLTWH(x + patternWidth - 6, 0, 12, 6),
          shapePaint
        );
      }

      var centerX = x + patternWidth / 2;
      var p1 = Offset(centerX - dotXDist, dotYOff);
      var p2 = Offset(centerX + dotXDist, dotYOff);
      var p3 = Offset(centerX, dotYOff + dotYDist);
      canvas.drawCircle(p1, dotRadius, shapePaint);
      canvas.drawCircle(p2, dotRadius, shapePaint);
      canvas.drawCircle(p3, dotRadius, shapePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
