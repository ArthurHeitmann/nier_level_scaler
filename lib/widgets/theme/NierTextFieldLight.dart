
import 'package:flutter/material.dart';

import '../misc/onHoverBuilder.dart';
import 'customTheme.dart';

class NierTextFieldLight extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final double? width;
  final void Function(String)? onChanged;

  const NierTextFieldLight({ super.key, this.controller, this.hintText, this.width, this.onChanged });

  @override
  State<NierTextFieldLight> createState() => _NierTextFieldLightState();
}

class _NierTextFieldLightState extends State<NierTextFieldLight> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OnHoverBuilder(
      builder: (context, isHovered) {
        return Container(
          width: widget.width ?? 300,
          height: 32,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 3),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(
              color: NierTheme.grey,
              width: 3,
            ))
          ),
          child: TextField(
            focusNode: focusNode,
            controller: widget.controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: NierTheme.brownDark
              )
            ),
            style: const TextStyle(
              color: NierTheme.brownDark,
              fontSize: 18,
            )
          ),
        );
      }
    );
  }
}
