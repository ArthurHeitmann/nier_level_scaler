
import 'dart:io';

import 'package:path/path.dart';

import '../fileTypeUtils/cpk/cpk.dart';
import '../fileTypeUtils/utils/ByteDataWrapper.dart';
import '../fileTypeUtils/dat/datExtractor.dart';
import 'emInfo.dart';


Future<List<EmInfo>> prepareFiles(Directory dataDir, Directory workingDir, bool forceExtract) async {
  var isWorkingDirEmpty = (await workingDir.list().toList()).isEmpty;
  if (!forceExtract && !isWorkingDirEmpty) {
    var emDats = await _findAllEmInfos(workingDir);
    if (emDats.isNotEmpty)
      return emDats;
  }
  return _extractAlEmDats(dataDir, workingDir);
}

const _datExtractSubDir = "nier2blender_extracted";
Future<List<EmInfo>> _findAllEmInfos(Directory workingDir) async {
  var extractDir = join(workingDir.path, _datExtractSubDir);
  var emSubFolders = (await Directory(extractDir)
    .list().toList())
    .whereType<Directory>()
    .where((e) => basename(e.path).startsWith("em") && e.path.endsWith(".dat"))
    .toList();
  print("Found ${emSubFolders.length} EM DATs");

  List<EmInfo> emInfos = [];
  for (var emSubFolder in emSubFolders) {
    var datFiles = await emSubFolder
      .list()
      .where((e) => e is File)
      .toList();
    var emInfo = _tryMakeEmInfo(emSubFolder, datFiles.cast<File>());
    if (emInfo == null) {
      continue;
    }
    emInfos.add(emInfo);
  }
  print("Found ${emInfos.length} EM DATs");
  return emInfos;
}

const _emCpks = [
  "data006.cpk",
  "data016.cpk",
  "data100.cpk",
];
Future<List<EmInfo>> _extractAlEmDats(Directory dataDir, Directory workingDir) async {
  List<File> emDats = [];
  print("Extracting DATs from CPKs...");
  for (var cpkName in _emCpks) {
    var cpkPath = join(dataDir.path, cpkName);
    if (!await File(cpkPath).exists()) {
      print("WARNING: $cpkName cpk not found!");
      continue;
    }
    print("Extracting $cpkName");
    var cpk = Cpk.read(await ByteDataWrapper.fromFile(cpkPath));
    for (var cpkFileData in cpk.files) {
      if (!cpkFileData.name.startsWith("em") || !cpkFileData.name.endsWith(".dat"))
        continue;
      print("Extracting ${cpkFileData.name}");
      var emDat = await cpkFileData.extractTo(workingDir.path);
      emDats.add(emDat);
    }
  }
  print("Extracted ${emDats.length} EM DATs");

  print("Extracting DATs...");
  List<EmInfo> emInfos = [];
  var extractDir = Directory(join(workingDir.path, _datExtractSubDir));
  if (!await extractDir.exists())
    await extractDir.create(recursive: true);
  for (var emDat in emDats) {
    var datExtractDir = Directory(join(extractDir.path, basename(emDat.path)));
    var datFiles = await extractDatFiles(emDat.path, datExtractDir.path);
    var emInfo = _tryMakeEmInfo(datExtractDir, datFiles.map((e) => File(e)).toList());
    if (emInfo == null) {
      continue;
    }
    emInfos.add(emInfo);
  }
  print("Extracted ${emInfos.length} EM DATs");
  return emInfos;
}

const _expInfoEnd = "ExpInfo.csv";
final _baseInfoRegex = RegExp(r"BaseInfo\d*\.csv");
EmInfo? _tryMakeEmInfo(Directory datDir, List<File> files) {
  var expInfoIndex = files.indexWhere((e) => basename(e.path).substring(6) == _expInfoEnd);
  if (expInfoIndex == -1)
    return null;
  var expInfo = files[expInfoIndex];
  var baseInfos = files.where((e) => _baseInfoRegex.hasMatch(basename(e.path))).toList();
  var emId = basename(datDir.path).substring(0, 6);
  String? actualEmId = basename(expInfo.path).substring(0, 6);
  if (emId == actualEmId)
    actualEmId = null;
  return EmInfo(emId, actualEmId, datDir, expInfo, baseInfos);
}
