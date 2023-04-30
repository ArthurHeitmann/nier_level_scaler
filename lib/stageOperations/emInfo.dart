
import 'dart:io';

import 'package:path/path.dart';

import '../fileTypeUtils/dat/datRepacker.dart';
import 'csvTable.dart';

class EmInfo {
  String name;
  String emId;
  String? actualEmId;
  Directory datDir;
  File expInfoCsv;
  CsvNumTable? expInfo;
  List<File> baseInfosCsv;

  EmInfo(this.emId, this.actualEmId, this.datDir, this.expInfoCsv, this.baseInfosCsv)
    : name = emId;

  String getEmIdWithHint() {
    if (actualEmId == null)
      return emId;
    return "$emId ($actualEmId)";
  }

  Future<void> loadExpInfoTable() async {
    expInfo = await CsvNumTable.fromFile(expInfoCsv, 3);
  }

  Future<void> exportDat(String gameDataDir) async {
    var exportPath = join(gameDataDir, "em", "$emId.dat");
    await repackDat(datDir.path, exportPath);
    print("Exported $exportPath");
  }

  @override
  bool operator ==(Object other) {
    if (other is EmInfo) {
      return emId == other.emId && actualEmId == other.actualEmId && datDir.path == other.datDir.path && expInfoCsv.path == other.expInfoCsv.path && baseInfosCsv.length == other.baseInfosCsv.length && baseInfosCsv.every((e) => other.baseInfosCsv.contains(e));
    }
    return false;
  }
  @override
  int get hashCode => Object.hashAll([emId, actualEmId, datDir.path, expInfoCsv.path, baseInfosCsv]);
}
