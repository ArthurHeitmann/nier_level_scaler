import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../misc/ChangeNotifierWidget.dart';
import '../misc/onHoverBuilder.dart';
import 'customTheme.dart';

class NierNumberTextField extends ChangeNotifierWidget {
  final String? Function(num)? validator;
  final ValueNotifier<num> value;
  final bool isInt;
  final num? min;
  final num? max;

  NierNumberTextField({
    super.key,
    required this.value,
    this.min,
    this.max,
    this.validator,
    bool? isInt,
  })  : isInt = isInt ?? value.value is int,
        super(notifier: value);

  @override
  State<NierNumberTextField> createState() => _NierNumberTextFieldState();
}

class _NierNumberTextFieldState
    extends ChangeNotifierState<NierNumberTextField> {
  final focusNode = FocusNode();
  final controller = TextEditingController();
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChanged);
    controller.text = widget.value.value.toStringUpTo(2);
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onChanged(String text) {
    if (!runValidator(text))
      return;
    onValid(text);
  }

  @override
  void onNotified() {
    var newText = widget.value.value.toStringUpTo(2);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
          offset: clamp(controller.selection.baseOffset, 0, newText.length)),
    );
    runValidator(controller.text);
    super.onNotified();
  }

  String? textValidator(String str) {
    String? err;
    if (widget.isInt && !isInt(str))
      err = "Not a valid integer";
    else if (!widget.isInt && !isDouble(str))
      err = "Not a valid number";
    else {
      var numVal = num.parse(str);
      if (widget.validator != null) err = widget.validator!(numVal);
      if (widget.min != null && numVal < widget.min!)
        err = "Must be at least ${widget.min}";
      else if (widget.max != null && numVal > widget.max!)
        err = "Must be at most ${widget.max}";
    }
    return err;
  }

  bool runValidator(String text) {
    var err = textValidator(text);
    if (err != null) {
      if (errorMsg != err) setState(() => errorMsg = err);
      return false;
    }
    if (errorMsg != null) setState(() => errorMsg = null);
    return true;
  }

  void onValid(String text) {
    var numVal = widget.isInt ? int.parse(text) : double.parse(text);
    widget.value.value = numVal;
  }

  @override
  Widget build(BuildContext context) {
    var scrollController = ScrollController(keepScrollOffset: false);
    return OnHoverBuilder(
      builder: (context, isHovered) {
        return Container(
          width: 40,
          height: 32,
          padding: const EdgeInsets.only(left: 2, right: 2, bottom: 3),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(
                color: NierTheme.grey,
                width: 3,
              ))
          ),
          child: Row(
            children: [
              Flexible(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: _onChanged,
                  scrollController: scrollController,
                  maxLines: 1,
                  clipBehavior: Clip.none,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: NierTheme.brownDark,
                    fontSize: 18,
                  )
                ),
              ),
              if (errorMsg != null)
                Tooltip(
                  message: errorMsg!,
                  decoration: BoxDecoration(
                    color: NierTheme.orange,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: NierTheme.orange,
                    size: 15,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        );
      }
    );
  }
}
