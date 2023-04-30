
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import '../../main.dart';
import '../../utils/utils.dart';
import '../../stageOperations/levelData.dart';
import '../../stageOperations/loadFiles.dart';
import '../../widgets/misc/infoDialog.dart';
import '../savableNotifier.dart';
import 'editLevels.dart';
import 'stages.dart';


class StageSetup extends Stage {
  SavableNotifier<String> gameDataDir;
  SavableNotifier<String> workingDir;
  ValueNotifier<bool> hasLoaded = ValueNotifier(false);

  StageSetup(Stages stages) :
    gameDataDir = SavableNotifierString("gameDataDir", ""),
    workingDir = SavableNotifierString("workingDir", ""),
    super(stages, StageType.setup) {
    gameDataDir.addListener(checkIsValid);
    workingDir.addListener(checkIsValid);
  }

  @override
  Future<void> checkIsValid() async {
    bool arePathsSet = gameDataDir.value.isNotEmpty && workingDir.value.isNotEmpty;
    isValid.value = arePathsSet && hasLoaded.value;
  }

  Future<void> selectGameDataPath() async {
    var path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select Game Directory",
    );
    if (path == null)
      return;
    
    var folderContents = await Directory(path)
      .list()
      .toList();
    // 2 shortcut cases:
    // 1. Game Dir (has data folder and NieRAutomata.exe)
    // 2. data folder (has at least 3 CPK files)
    var gameDataPathRes = await _gameDataPathFromGameDir(path, folderContents);
    if (gameDataPathRes == null) {
      gameDataPathRes = await _gameDataPathFromDataDir(path, folderContents);
      if (gameDataPathRes == null) {
        await infoDialog(getGlobalContext(), text: "Invalid Game Directory");
        print("Couldn't find game data path in $path");
        return;
      }
    }
    gameDataDir.value = gameDataPathRes;
  }

  Future<String?> _gameDataPathFromGameDir(String path, List<FileSystemEntity> folderContents) async {
    if (!folderContents.any((f) => f is Directory && basename(f.path) == "data"))
      return null;
    if (!folderContents.any((f) => f is File && basename(f.path) == "NieRAutomata.exe"))
      return null;
    var gameDataPath = join(path, "data");
    if (!await File(gameDataPath).exists())
      return null;
    return gameDataPath;
  }

  Future<String?> _gameDataPathFromDataDir(String path, List<FileSystemEntity> folderContents) async {
    const mustHaveFiles = {
      "data006.cpk",
      "data016.cpk",
      "data100.cpk",
    };
    var hassAllNeededFiles = mustHaveFiles
      .every((f) => folderContents.any((e) => e is File && basename(e.path) == f));
    if (!hassAllNeededFiles)
      return null;
    return path;
  }

  Future<void> selectWorkingDir() async {
    var path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select Working Directory",
    );
    if (path == null)
      return;
    workingDir.value = path;
  }

  Future<void> loadFiles() async {
    var pathsStage = stages.stages.whereType<StageSetup>().first;
    var gameDataDir = Directory(pathsStage.gameDataDir.value);
    var workingDir = Directory(pathsStage.workingDir.value);
    var levelData = LevelData();
    var emInfos = await prepareFiles(gameDataDir, workingDir, false);
    print("Loading enemy infos...");
    await waitBatched(emInfos.map((emInfo) => emInfo.loadExpInfoTable()), 5);
    print("Initializing level data...");
    levelData.initializeWith(emInfos);
    var levelsStage = stages.stages.whereType<StageEditLevels>().first;
    levelsStage.levelData.value?.dispose();
    levelsStage.levelData.value = levelData;
    hasLoaded.value = true;
    isValid.value = true;
    stages.currentStage.value++;
    print("Done!");
  }
}