
import 'package:flutter/material.dart';

import '../../utils/checkedState.dart';
import '../misc/ChangeNotifierWidget.dart';
import 'customTheme.dart';

class NierCheckbox extends ChangeNotifierWidget {
  final ValueNotifier<CheckState>? state;
  final ValueNotifier<bool>? isChecked;
  final Color? activeColor;
  final Color? hoverColor;

  NierCheckbox({
    super.key,
    this.state,
    this.isChecked,
    this.activeColor,
    this.hoverColor,
  }) : super(notifier: state ?? isChecked) {
    assert(state != null || isChecked != null);
  }

  @override
  State<NierCheckbox> createState() => _NierCheckboxState();
}

class _NierCheckboxState extends ChangeNotifierState<NierCheckbox> {
  bool? get value => widget.state?.value.boolValue ?? widget.isChecked?.value;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      tristate: widget.state != null,
      fillColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.hovered))
          return widget.hoverColor ?? NierTheme.dark2;
        return widget.activeColor ?? NierTheme.brownDark;
      }),
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      onChanged: (value) {
        if (widget.state != null)
          widget.state!.value = widget.state!.value.next;
        else
          widget.isChecked!.value = value!;
      },
    );
  }
}
