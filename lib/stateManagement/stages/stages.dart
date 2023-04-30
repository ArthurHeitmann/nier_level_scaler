
import 'package:flutter/material.dart';

import 'editLevels.dart';
import 'export.dart';
import 'setup.dart';

enum StageType {
  setup("Setup", Icons.folder_open),
  editLevels("Edit Level Stats", Icons.handyman),
  export("Export", Icons.file_upload);

  const StageType(this.name, this.icon);
  final String name;
  final IconData icon;
}

abstract class Stage {
  Stages stages;
  ValueNotifier<bool> isValid;
  final StageType type;

  Stage(this.stages, this.type)
    : isValid = ValueNotifier(false);
  
  Future<void> checkIsValid();
}

abstract class SingleActionStage extends Stage {
  SingleActionStage(super.stages, super.type);

  void action();

  IconData? get actionIcon => null;
}

class Stages {
  late final List<Stage> stages;
  final ValueNotifier<int> currentStage = ValueNotifier(0);

  Stages() {
    stages = [
      StageSetup(this),
      StageEditLevels(this),
      StageExport(this),
    ];
    for (var stage in stages)
      stage.isValid.addListener(() => _onStageIsValidChanged(stage));
    stages.first.checkIsValid();
  }

  Future<void> _onStageIsValidChanged(Stage stage) async {
    if (stage.isValid.value) {
      // Check if the next stage is valid
      int nextStageIndex = stages.indexOf(stage) + 1;
      if (nextStageIndex < stages.length)
        await stages[nextStageIndex].checkIsValid();
    }
    else {
      // Invalidate all stages after this one
      for (int i = stages.indexOf(stage) + 1; i < stages.length; i++)
        stages[i].isValid.value = false;
    }
  }
}
