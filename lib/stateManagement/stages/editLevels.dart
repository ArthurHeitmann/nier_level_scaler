
import 'package:flutter/foundation.dart';

import '../../stageOperations/levelData.dart';
import 'stages.dart';

class StageEditLevels extends Stage {
  ValueNotifier<LevelData?> levelData = ValueNotifier(null);
  
  StageEditLevels(Stages stages) : super(stages, StageType.editLevels);
  
  @override
  Future<void> checkIsValid() async {
    isValid.value = true;
  }
}
