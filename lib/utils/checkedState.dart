
enum CheckState {
  unchecked,
  checked,
  indeterminate;

  CheckState get next {
    switch (this) {
      case CheckState.unchecked:
        return CheckState.checked;
      case CheckState.checked:
        return CheckState.unchecked;
      case CheckState.indeterminate:
        return CheckState.unchecked;
    }
  }

  bool? get boolValue {
    switch (this) {
      case CheckState.unchecked:
        return false;
      case CheckState.checked:
        return true;
      case CheckState.indeterminate:
        return null;
    }
  }
}
