
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

import '../stateManagement/HierachyEntry.dart';
import '../stateManagement/listNotifier.dart';
import '../utils/checkedState.dart';
import '../utils/utils.dart';
import 'csvTable.dart';
import 'emInfo.dart';
import 'emNamesAndCategories.dart';

class EmExpInfoSnapshot {
  final EmInfo emInfo;
  final List<double> hpLevels;
  final List<double> atkLevels;
  final List<double> defLevels;
  final List<List<double>> categories;

  EmExpInfoSnapshot({
    required this.emInfo,
    required this.hpLevels,
    required this.atkLevels,
    required this.defLevels,
  }) : categories = [hpLevels, atkLevels, defLevels];

  EmExpInfoSnapshot copy() => EmExpInfoSnapshot(
    emInfo: emInfo,
    hpLevels: List.from(hpLevels, growable: false),
    atkLevels: List.from(atkLevels, growable: false),
    defLevels: List.from(defLevels, growable: false),
  );

  void multiplyInPlace(int index, double factor, { int minLevel = 1, int maxLevel = 99 }) {
    minLevel--;
    maxLevel--;
    for (var i = minLevel; i <= maxLevel; i++)
      categories[index][i] *= factor;
  }

  Future<void> writeToCsv() async {
    var table = emInfo.expInfo!;
    for (int i = 0; i < categories.length; i++) {
      for (int level = 0; level < 99; level++) {
        table.rows[level].values[i] = categories[i][level].round();
      }
    }
    await backupFile(emInfo.expInfoCsv.path);
    await table.toFile(emInfo.expInfoCsv);
  }
}

class ExpOperation extends ChangeNotifier {
  // inputs+outputs
  final Map<EmInfo, EmExpInfoSnapshot> Function() getInputs;
  final Map<EmInfo, EmExpInfoSnapshot> outputs;
  bool hasPendingChanges = false;
  // filters
  List<EmInfo> emInfoFilter;
  int levelMinFilter;
  int levelMaxFilter;
  bool hpFilter;
  bool atkFilter;
  bool defFilter;
  // parameters
  double multiplier;
  // averages for em selection
  List<double> avrHp = [];
  List<double> avrAtk = [];
  List<double> avrDef = [];
  // averages for em selection of inputs
  List<double> avrHpInputs = [];
  List<double> avrAtkInputs = [];
  List<double> avrDefInputs = [];

  ExpOperation({
    required this.getInputs,
    required this.emInfoFilter,
    required this.levelMinFilter,
    required this.levelMaxFilter,
    required this.hpFilter,
    required this.atkFilter,
    required this.defFilter,
    required this.multiplier,
  }) :
    outputs = _copyInputs(getInputs)
  {
    _calculateAverages();
  }

  String toUiString(int index) {
    return
      "Operation ${index + 1},"
      " ${emInfoFilter.length} EMs,"
      " ${levelMinFilter}-${levelMaxFilter},"
      " x${multiplier.toStringUpTo(2)}";
  }

  static _copyInputs(Map<EmInfo, EmExpInfoSnapshot> Function() getInputs) {
    var inputs = getInputs();
    return Map.fromEntries([
      for (var entry in inputs.entries)
        MapEntry(entry.key, entry.value.copy()),
    ]);
  }

  ExpOperation makeNext() {
    return ExpOperation(
      getInputs: () => outputs,
      emInfoFilter: emInfoFilter.toList(),
      levelMinFilter: 1,
      levelMaxFilter: 99,
      hpFilter: true,
      atkFilter: true,
      defFilter: true,
      multiplier: 1.0,
    );
  }

  void onParametersChanged() {
    recalculate();
    notifyListeners();
  }

  void recalculate() {
    _updateOutputs();
    _calculateAverages();
  }

  void checkForPendingChanges() {
    if (!hasPendingChanges)
      return;
    recalculate();
    hasPendingChanges = false;
  }

  void _updateOutputs() {
    outputs.clear();
    outputs.addAll(_copyInputs(getInputs));

    for (var emInfo in emInfoFilter) {
      var emExpInfoSnapshot = outputs[emInfo]!;
      if (hpFilter)
        emExpInfoSnapshot.multiplyInPlace(0, multiplier, minLevel: levelMinFilter, maxLevel: levelMaxFilter);
      if (atkFilter)
        emExpInfoSnapshot.multiplyInPlace(1, multiplier, minLevel: levelMinFilter, maxLevel: levelMaxFilter);
      if (defFilter)
        emExpInfoSnapshot.multiplyInPlace(2, multiplier, minLevel: levelMinFilter, maxLevel: levelMaxFilter);
    }
  }

  void _calculateAverages() {
    avrHp = _calculateAveragesOf(outputs, 0);
    avrAtk = _calculateAveragesOf(outputs, 1);
    avrDef = _calculateAveragesOf(outputs, 2);
    var inputs = getInputs();
    avrHpInputs = _calculateAveragesOf(inputs, 0);
    avrAtkInputs = _calculateAveragesOf(inputs, 1);
    avrDefInputs = _calculateAveragesOf(inputs, 2);
  }

  List<double> _calculateAveragesOf(Map<EmInfo, EmExpInfoSnapshot> rawValues, int column) {
    var values = _getColumnValues(rawValues, column);
    var averaged = _averageValues(values);
    return averaged;
  }
  List<List<double>> _getColumnValues(Map<EmInfo, EmExpInfoSnapshot> rawValues, int column) {
    return rawValues.values
      .where((e) => emInfoFilter.contains(e.emInfo))
      .map((e) => e.categories[column])
      .toList(growable: false);
  }
}

class LevelData extends ChangeNotifier {
  Map<EmInfo, EmExpInfoSnapshot>? _initialOpInputs;
  final List<ExpOperation> _operations = [];
  Iterable<ExpOperation> get operations => _operations.skip(1);
  ValueNotifier<int> currentOpI = ValueNotifier(0);
  ExpOperation get currentOp => _operations[currentOpI.value];
  HierarchyEntry? rootGroup;
  // filters
  ValueNotifier<int> levelMinFilter = ValueNotifier(1);
  ValueNotifier<int> levelMaxFilter = ValueNotifier(99);
  ValueNotifier<bool> hpFilter = ValueNotifier(true);
  ValueNotifier<bool> atkFilter = ValueNotifier(true);
  ValueNotifier<bool> defFilter = ValueNotifier(true);
  // parameters
  ValueNotifier<double> multiplier = ValueNotifier(1.0);

  LevelData() {
    currentOpI.addListener(_onCurrentOpChanged);
    levelMinFilter.addListener(_onOpParamsChanged);
    levelMaxFilter.addListener(_onOpParamsChanged);
    hpFilter.addListener(_onOpParamsChanged);
    atkFilter.addListener(_onOpParamsChanged);
    defFilter.addListener(_onOpParamsChanged);
    multiplier.addListener(_onOpParamsChanged);
  }

  void initializeWith(List<EmInfo> initialEnemyLevelData) {
    _organizeIntoGroups(initialEnemyLevelData);
    _makeInitialOperation(initialEnemyLevelData);
  }

  void _organizeIntoGroups(List<EmInfo> initialEnemyLevelData) {
    String uncategorizedName = "Uncategorized";
    var targetGroupOrder = emCategories.followedBy([uncategorizedName]);
    Map<String, List<EmInfo>> emInfosByEmCategory = LinkedHashMap.fromEntries([
      for (var category in targetGroupOrder)
        MapEntry(category, []),
    ]);
    for (var emInfo in initialEnemyLevelData) {
      var emDbInfo = emNamesAndCategories.where((e) => e.emId == emInfo.emId);
      String emName;
      String emCategory;
      if (emDbInfo.isNotEmpty) {
        emName = "${emDbInfo.first.name} (${emInfo.getEmIdWithHint()})";
        emCategory = emDbInfo.first.category;
      } else {
        emName = emInfo.getEmIdWithHint();
        emCategory = uncategorizedName;
      }
      emInfo.name = emName;
      if (!emInfosByEmCategory.containsKey(emCategory))
        emInfosByEmCategory[emCategory] = [];
      emInfosByEmCategory[emCategory]!.add(emInfo);
    }
    for (var catEntries in emInfosByEmCategory.values) {
      catEntries.sort((a, b) {
        var aSortId = emIdToSortId[a.emId];
        var bSortId = emIdToSortId[b.emId];
        if (aSortId == null || bSortId == null)
          return a.emId.compareTo(b.emId);
        return aSortId.compareTo(bSortId);
      });
    }
    var categoryGroups = emInfosByEmCategory.entries
      .map((e) => HierarchyEntry(
        name: e.key,
        isCollapsed: true,
        children: e.value
          .map((e) => EmHierarchyEntry(
            name: e.name,
            emInfo: e,
          ))
          .toList(),
      ));

    rootGroup = HierarchyEntry(
      name: "All",
      children: categoryGroups.toList(),
    );
    rootGroup!.checkState.value = CheckState.checked;
    for (var child in rootGroup!.allChildren.whereType<EmHierarchyEntry>())
      child.checkState.addListener(_onEmCheckStateChanged);
  }

  void _makeInitialOperation(List<EmInfo> initialEnemyLevelData) {
    _initialOpInputs = {
      for (var emInfo in initialEnemyLevelData)
        emInfo: EmExpInfoSnapshot(
          emInfo: emInfo,
          hpLevels: emInfo.expInfo!.getColumn(0).map((n) => n.toDouble()).toList(),
          atkLevels: emInfo.expInfo!.getColumn(1).map((n) => n.toDouble()).toList(),
          defLevels: emInfo.expInfo!.getColumn(2).map((n) => n.toDouble()).toList(),
        ),
    };
    var initialOp = ExpOperation(
      getInputs: () => _initialOpInputs!,
      emInfoFilter: initialEnemyLevelData.toList(),
      levelMinFilter: 1,
      levelMaxFilter: 99,
      hpFilter: true,
      atkFilter: true,
      defFilter: true,
      multiplier: 1.0,
    );
    initialOp.addListener(() => _onOperationChanged(initialOp));
    _operations.add(initialOp);
    addNewOperation();
  }

  @override
  void dispose() {
    for (var op in _operations)
      op.dispose();
    for (var child in rootGroup?.allChildren ?? const Iterable.empty())
      child.dispose();
    rootGroup?.dispose();
    super.dispose();
  }

  void addNewOperation() {
    var newOp = _operations.first.makeNext();
    newOp.addListener(() => _onOperationChanged(newOp));
    _operations.add(newOp);
    currentOpI.value = _operations.length - 1;
    notifyListeners();
  }

  void removeOperation(ExpOperation op) {
    _operations.remove(op);
    op.dispose();
    if (currentOpI.value >= _operations.length)
      currentOpI.value = _operations.length - 1;
    notifyListeners();
  }

  void removeCurrentOperation() {
    removeOperation(currentOp);
  }

  void checkAllOperationsForPendingChanges() {
    for (var op in _operations)
      op.checkForPendingChanges();
  }

  void _onOperationChanged(ExpOperation op) {
    var opIndex = _operations.indexOf(op);
    if (opIndex == -1)
      throw Exception("Operation not found");
    for (var i = opIndex + 1; i < _operations.length; i++) {
      _operations[i].recalculate();
    }
    notifyListeners();
  }

  void _onCurrentOpChanged() {
    var operation = currentOp;
    levelMinFilter.value = operation.levelMinFilter;
    levelMaxFilter.value = operation.levelMaxFilter;
    hpFilter.value = operation.hpFilter;
    atkFilter.value = operation.atkFilter;
    defFilter.value = operation.defFilter;
    multiplier.value = operation.multiplier;
    operation.checkForPendingChanges();
  }

  void _onOpParamsChanged() {
    var operation = currentOp;
    operation.levelMinFilter = levelMinFilter.value;
    operation.levelMaxFilter = levelMaxFilter.value;
    operation.hpFilter = hpFilter.value;
    operation.atkFilter = atkFilter.value;
    operation.defFilter = defFilter.value;
    operation.multiplier = multiplier.value;
    operation.hasPendingChanges = true;
    notifyListeners();
  }

  void _onEmCheckStateChanged() {
    var operation = currentOp;
    var emInfoFilter = rootGroup!.allChildren
      .whereType<EmHierarchyEntry>()
      .where((e) => e.checkState.value == CheckState.checked)
      .map((e) => e.emInfo)
      .toList();
    operation.emInfoFilter = emInfoFilter;
    operation.hasPendingChanges = true;
    notifyListeners();
  }
}

List<double> _averageValues(List<List<double>> valuesList) {
  if (valuesList.isEmpty)
    return List.empty();
  var len = valuesList.first.length;
  for (var list in valuesList) {
    if (list.length != len)
      throw Exception("All lists must have the same length");
  }
  var averages = List<double>.filled(len, 0.0);
  for (var i = 0; i < len; i++) {
    for (var list in valuesList) {
      averages[i] += list[i];
    }
    averages[i] /= valuesList.length;
  }
  return averages;
}
