
import 'package:flutter/foundation.dart';

import '../stageOperations/emInfo.dart';
import '../utils/checkedState.dart';

class HierarchyEntry<T> {
  final String name;
  final List<HierarchyEntry<T>> children;
  final T? data;
  final ValueNotifier<bool> isCollapsed;
  final bool canBeChecked;
  final ValueNotifier<CheckState> checkState;

  HierarchyEntry({
    required this.name,
    this.children = const [],
    this.data,
    bool isCollapsed = false,
    this.canBeChecked = true,
    CheckState checkState = CheckState.unchecked,
  }) :
    isCollapsed = ValueNotifier(isCollapsed),
    checkState = ValueNotifier(checkState) {
    this.checkState.addListener(_onCheckStateChanged);
    for (var child in children)
      child.checkState.addListener(() => _onChildCheckStateChanged(child));
  }

  bool get canBeCollapsed => children.isNotEmpty;

  Iterable<HierarchyEntry<T>> get allChildren sync* {
    for (var child in children) {
      yield child;
      yield* child.allChildren;
    }
  }

  @mustCallSuper
  void dispose() {
    isCollapsed.dispose();
    checkState.dispose();
  }

  void _onCheckStateChanged() {
    if (checkState.value == CheckState.unchecked) {
      for (var child in children)
        child.checkState.value = CheckState.unchecked;
    } else if (checkState.value == CheckState.checked) {
      for (var child in children)
        child.checkState.value = CheckState.checked;
    }
  }

  void _onChildCheckStateChanged(HierarchyEntry child) {
    if (child.checkState.value == CheckState.unchecked) {
      bool allUnselected = children
        .every((child) => child.checkState.value == CheckState.unchecked);
      if (allUnselected)
        checkState.value = CheckState.unchecked;
      else
        checkState.value = CheckState.indeterminate;
    } else if (child.checkState.value == CheckState.checked) {
      bool allSelected = children
        .every((child) => child.checkState.value == CheckState.checked);
      if (allSelected)
        checkState.value = CheckState.checked;
      else
        checkState.value = CheckState.indeterminate;
    } else if (child.checkState.value == CheckState.indeterminate) {
      checkState.value = CheckState.indeterminate;
    }
  }

  bool isVisibleWithSearchQuery(String query) {
    // true if:
    // - self is visible with search query
    // - any recursive child is visible with search query
    query = query.toLowerCase();
    if (_isSelfVisibleWithSearchQuery(query))
      return true;
    for (var child in children) {
      if (child.isVisibleWithSearchQuery(query))
        return true;
    }
    return false;
  }
  bool _isSelfVisibleWithSearchQuery(String query) {
    return name.toLowerCase().contains(query);
  }
}

class EmHierarchyEntry extends HierarchyEntry {
  final EmInfo emInfo;

  EmHierarchyEntry({
    required super.name,
    required this.emInfo,
    super.children,
    super.data,
    super.isCollapsed,
    super.canBeChecked,
    super.checkState,
  });
}
