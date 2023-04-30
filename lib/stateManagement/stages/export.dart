
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/misc/infoDialog.dart';
import '../dataInstances.dart';
import 'editLevels.dart';
import 'setup.dart';
import 'stages.dart';

class StageExport extends SingleActionStage {
  StageExport(Stages stages) : super(stages, StageType.export);
  
  @override
  Future<void> checkIsValid() async {
    isValid.value = true;
  }

  @override
  IconData? get actionIcon => Icons.file_upload;

  Future<void> action() async {
    statusInfo.isBusy.value = true;
    try {
      var setupStage = stages.stages
          .whereType<StageSetup>()
          .first;
      var editLevelsStage = stages.stages
          .whereType<StageEditLevels>()
          .first;
      var levelData = editLevelsStage.levelData.value;
      if (levelData == null) {
        infoDialog(getGlobalContext(), text: "No data to export");
        return;
      }
      var allEditedEmInfos = levelData.operations
          .where((op) => op.multiplier != 1)
          .map((op) => op.emInfoFilter)
          .expand((emInfos) => emInfos)
          .toSet();
      var changedLevelDatas = levelData
          .operations
          .last
          .outputs
          .entries
          .where((entry) => allEditedEmInfos.contains(entry.key))
          .map((entry) => entry.value);
      if (changedLevelDatas.isEmpty) {
        infoDialog(getGlobalContext(), text: "No changes to export");
        return;
      }
      var gameDataDir = setupStage.gameDataDir.value;
      for (var levelData in changedLevelDatas) {
        await levelData.writeToCsv();
        await levelData.emInfo.exportDat(gameDataDir);
      }
    } finally {
      statusInfo.isBusy.value = false;
    }
  }
}
