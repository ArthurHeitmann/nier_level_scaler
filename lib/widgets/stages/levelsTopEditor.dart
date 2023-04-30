
import 'package:flutter/material.dart';

import '../../stageOperations/levelData.dart';
import '../../stateManagement/stages/editLevels.dart';
import '../../utils/utils.dart';
import '../misc/debugContainer.dart';
import '../theme/NierCheckbox.dart';
import '../theme/NierNumberTextField.dart';
import '../theme/customTheme.dart';

class LevelsTopEditor extends StatefulWidget {
  final StageEditLevels stage;

  const LevelsTopEditor({ super.key, required this.stage });

  @override
  State<LevelsTopEditor> createState() => _LevelsTopEditorState();
}

class _LevelsTopEditorState extends State<LevelsTopEditor> {
  Listenable? currentNotifier;
  ValueNotifier<String> searchQuery = ValueNotifier<String>("");

  LevelData? get levelData => widget.stage.levelData.value;

  @override
  void initState() {
    super.initState();
    widget.stage.levelData.addListener(_onLevelDataChanged);
    widget.stage.isValid.addListener(_onLevelDataChanged);
    _onLevelDataChanged();
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
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        _makeCategoryFilter(),
        _makeLevelMinMaxFilter(),
        _makeMultiplierSlider(),
      ],
    );
  }

  Widget _makeCategoryFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NierCheckbox(
          isChecked: levelData!.hpFilter,
          activeColor: NierTheme.hpColor,
        ),
        const Text("HP", style: TextStyle(color: NierTheme.dark2),),
        const SizedBox(width: 10),
        NierCheckbox(
          isChecked: levelData!.atkFilter,
          activeColor: NierTheme.atkColor,
        ),
        const Text("ATK", style: TextStyle(color: NierTheme.dark2),),
        const SizedBox(width: 10),
        NierCheckbox(
          isChecked: levelData!.defFilter,
          activeColor: NierTheme.defColor,
        ),
        const Text("DEF", style: TextStyle(color: NierTheme.dark2),),
      ],
    );
  }

  Widget _makeLevelMinMaxFilter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Level range", style: TextStyle(color: NierTheme.dark2),),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NierNumberTextField(
              value: levelData!.levelMinFilter,
              min: 1,
              max: 99,
              isInt: true,
              validator: (num newMin) {
                if (newMin > levelData!.levelMaxFilter.value)
                  return "Min must be less than max";
                return null;
              },
            ),
            RangeSlider(
              min: 1,
              max: 99,
              divisions: 98,
              activeColor: NierTheme.brownDark,
              inactiveColor: NierTheme.brownLight,
              values: RangeValues(
                levelData!.levelMinFilter.value.toDouble(),
                levelData!.levelMaxFilter.value.toDouble(),
              ),
              onChanged: (value) {
                levelData!.levelMinFilter.value = value.start.toInt();
                levelData!.levelMaxFilter.value = value.end.toInt();
              },
            ),
            NierNumberTextField(
              value: levelData!.levelMaxFilter,
              min: 1,
              max: 99,
              isInt: true,
              validator: (num newMax) {
                if (newMax < levelData!.levelMinFilter.value)
                  return "Max must be greater than min";
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _makeMultiplierSlider() {
    return Column(
      children: [
        const Text("Multiplier", style: TextStyle(color: NierTheme.dark2),),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              min: 0,
              max: 5,
              divisions: 5 * 10,
              activeColor: NierTheme.brownDark,
              inactiveColor: NierTheme.brownLight,
              value: clamp(levelData!.multiplier.value, 0, 5),
              onChanged: (value) => levelData!.multiplier.value = value,
            ),
            NierNumberTextField(
              value: levelData!.multiplier,
              min: 0,
              isInt: false,
            ),
          ],
        ),
      ],
    );
  }
}
