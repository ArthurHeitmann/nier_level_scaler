
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:tuple/tuple.dart';

import '../../stateManagement/stages/editLevels.dart';
import '../../stageOperations/levelData.dart';
import '../../utils/utils.dart';
import '../misc/ChangeNotifierWidget.dart';
import '../theme/NierButton.dart';
import '../theme/NierHierarchyEntry.dart';
import '../theme/NierListView.dart';
import '../theme/NierPopupSelection.dart';
import '../theme/NierTextFieldLight.dart';
import '../theme/customTheme.dart';

class LevelsEditor extends StatefulWidget {
  final StageEditLevels stage;

  const LevelsEditor({ super.key, required this.stage });

  @override
  State<LevelsEditor> createState() => _LevelsEditorState();
}

class _LevelsEditorState extends State<LevelsEditor> {
  Listenable? currentNotifier;
  final ValueNotifier<String> searchQuery = ValueNotifier<String>("");
  final maxValueInTimeframe = _MaxValueInTimeframe(const Duration(milliseconds: 1500), 3);

  LevelData? get levelData => widget.stage.levelData.value;

  @override
  void initState() {
    super.initState();
    widget.stage.levelData.addListener(_onLevelDataChanged);
    widget.stage.isValid.addListener(_onLevelDataChanged);
  }

  @override
  void dispose() {
    super.dispose();
    widget.stage.levelData.removeListener(_onLevelDataChanged);
    widget.stage.isValid.removeListener(_onLevelDataChanged);
    currentNotifier?.removeListener(_onLevelDataChanged);
    searchQuery.dispose();
  }

  void _onLevelDataChanged() {
    if (currentNotifier != widget.stage.levelData.value) {
      currentNotifier?.removeListener(_onLevelDataChanged);
      currentNotifier = widget.stage.levelData.value;
      currentNotifier?.addListener(_onLevelDataChanged);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    levelData?.checkAllOperationsForPendingChanges();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (levelData != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _makeOperationsManager(),
              const SizedBox(height: 10),
              Expanded(
                child: _makeEmSelector()
              ),
            ],
          ),
          const SizedBox(width: 10),
          Flexible(
            child: _makeChart(),
          ),
        ],
      ],
    );
  }

  Widget _makeOperationsManager() {
    return ChangeNotifierBuilder(
      notifier: levelData!.currentOpI,
      builder: (context) {
        return ChangeNotifierBuilder(
          key: ValueKey(levelData!.currentOpI.value),
          notifier: levelData!.currentOp,
          builder: (context) {
            return Row(
              children: [
                NierPopupSelection(
                  options: List.generate(
                    levelData!.operations.length,
                    (index) => levelData!.operations.elementAt(index).toUiString(index)
                  ),
                  // getActiveText: (index) => "Operation ${index + 1}",
                  getActiveText: (index) => levelData!.operations.elementAt(index).toUiString(index),
                  selectedIndex: levelData!.currentOpI.value,
                  width: 350,
                  activeButtonWidth: 380,
                  onSelected: (index) => levelData!.currentOpI.value = index,
                ),
                const SizedBox(width: 10),
                NierButton(
                  icon: Icons.add,
                  width: 48,
                  onPressed: levelData!.addNewOperation,
                ),
                const SizedBox(width: 10),
                NierButton(
                  icon: Icons.remove,
                  width: 48,
                  onPressed: levelData!.operations.isNotEmpty ? levelData!.removeCurrentOperation : null,
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _makeEmSelector() {
    return NierListView(
      header: Padding(
        padding: const EdgeInsets.only(left: 12, right: 28, bottom: 8),
        child: NierTextFieldLight(
          hintText: "Search",
          onChanged: (value) => searchQuery.value = value,
        ),
      ),
      children: [
        if (levelData?.rootGroup != null)
          NierHierarchyEntry(
            entry: levelData!.rootGroup!,
            searchQuery: searchQuery,
          ),
      ],
    );
  }

  Widget _makeChart() {
    var allCurveData = [
      levelData!.currentOp.avrHp,
      levelData!.currentOp.avrAtk,
      levelData!.currentOp.avrDef,
      levelData!.currentOp.avrHpInputs,
      levelData!.currentOp.avrAtkInputs,
      levelData!.currentOp.avrDefInputs,
    ];
    var maxValue = allCurveData.expand((e) => e).fold(0.0, max);
    maxValueInTimeframe.addValue(maxValue);
    return Stack(
      children: [
        // shadow
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(4, 4),
            child: Container(
              color: NierTheme.grey,
            ),
          )
        ),
        // chart
        Positioned.fill(
          child: Container(
            color: NierTheme.light2,
            padding: const EdgeInsets.only(top: 8, left: 8),
            child: LineChart(
              LineChartData(
                lineBarsData: <Tuple2<Color, List<double>>>[
                  Tuple2(NierTheme.hpColor, levelData!.currentOp.avrHp),
                  Tuple2(NierTheme.atkColor, levelData!.currentOp.avrAtk),
                  Tuple2(NierTheme.defColor, levelData!.currentOp.avrDef),
                  Tuple2(NierTheme.hpColor.withOpacity(0.333), levelData!.currentOp.avrHpInputs),
                  Tuple2(NierTheme.atkColor.withOpacity(0.333), levelData!.currentOp.avrAtkInputs),
                  Tuple2(NierTheme.defColor.withOpacity(0.333), levelData!.currentOp.avrDefInputs),
                ].map((e) => LineChartBarData(
                  color: e.item1,
                  dotData: FlDotData(
                    show: false,
                  ),
                  isCurved: false,
                  barWidth: 3,
                  spots: List.generate(
                    e.item2.length,
                    (i) => FlSpot(i + 1, e.item2[i])
                  ),
                ))
                .toList(),
                minX: 1,
                maxX: 99,
                minY: 0,
                maxY: maxValueInTimeframe.getMaxValue(),
                gridData: FlGridData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    // axisNameWidget: const Text("HP"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2000,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          numberToShort(value),
                          style: const TextStyle(color: NierTheme.dark2, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                        ),
                      )
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Level", style: TextStyle(color: NierTheme.dark2, fontSize: 16, fontWeight: FontWeight.w500)),
                    axisNameSize: 25,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: NierTheme.dark2, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                        ),
                      )
                    )
                  ),
                  leftTitles: AxisTitles(),
                  topTitles: AxisTitles(),
                  // rightTitles: AxisTitles(),
                ),
                lineTouchData: LineTouchData(
                  enabled: false
                ),
                borderData: FlBorderData(
                  border: const Border(
                    bottom: BorderSide(color: NierTheme.brownLight, width: 2.5),
                    right: BorderSide(color: NierTheme.brownLight, width: 2.5)
                  ),
                ),
              ),
              // swapAnimationDuration: Duration.zero,
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
        ),
        // chart legend
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: NierTheme.brownDark, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Tuple2<String, Color>>[
                const Tuple2("HP", NierTheme.hpColor),
                const Tuple2("ATK", NierTheme.atkColor),
                const Tuple2("DEF", NierTheme.defColor),
              ].map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.item2,
                        // borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(e.item1, style: const TextStyle(color: NierTheme.dark, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ))
              .toList(),
            ),
          ),
        )
      ],
    );
  }
}

class _MaxValueInTimeframe {
  final Duration timeframe;
  final int minValues;
  final List<Tuple2<DateTime, double>> _values = [];
  bool _isDirty = false;
  double? _maxValue;

  _MaxValueInTimeframe(this.timeframe, this.minValues);

  void addValue(double value) {
    final time = DateTime.now();
    _values.add(Tuple2(time, value));
    _isDirty = true;
  }

  double getMaxValue() {
    if (_isDirty) {
      _removeOldValues();
      _maxValue = _values.map((e) => e.item2).reduce(max);
      _isDirty = false;
    }
    return _maxValue!;
  }

  void _removeOldValues() {
    if (_values.length < minValues)
      return;
    final cutoff = DateTime.now().subtract(timeframe);
    int valuesToRemove = 0;
    for (final value in _values) {
      if (value.item1.isAfter(cutoff))
        break;
      valuesToRemove++;
    }
    _values.removeRange(0, valuesToRemove);
  }
}
