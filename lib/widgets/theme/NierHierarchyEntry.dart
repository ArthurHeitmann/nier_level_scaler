
import 'package:flutter/material.dart';

import '../../stateManagement/HierachyEntry.dart';
import '../../utils/checkedState.dart';
import '../misc/ChangeNotifierWidget.dart';
import '../misc/objIdIcon.dart';
import '../misc/onHoverBuilder.dart';
import 'NierButtonFancy.dart';
import 'NierCheckbox.dart';
import 'customTheme.dart';


class NierHierarchyEntry extends ChangeNotifierWidget {
  final HierarchyEntry entry;
  final ValueNotifier<String>? searchQuery;

  NierHierarchyEntry({
    required this.entry,
    this.searchQuery,
  }) : super(
    key: ValueKey(entry),
    notifiers: [entry.isCollapsed, entry.checkState, if (searchQuery != null) searchQuery]
  );

  @override
  State<NierHierarchyEntry> createState() => _NierHierarchyEntryState();
}

class _NierHierarchyEntryState extends ChangeNotifierState<NierHierarchyEntry> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 5),
            if (widget.entry.canBeCollapsed) ...[
              _CollapsedIndicator(isCollapsed: widget.entry.isCollapsed),
              const SizedBox(width: 5),
            ],
            if (widget.entry.canBeChecked) ...[
              NierCheckbox(state: widget.entry.checkState),
              const SizedBox(width: 5),
            ],
            if (widget.entry is EmHierarchyEntry) ...[
              ObjIdIcon(objId: (widget.entry as EmHierarchyEntry).emInfo.emId),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(widget.entry.name, style: const TextStyle(color: NierTheme.dark2)),
            ),
          ],
        ),
        if (!widget.entry.isCollapsed.value)
          ...widget.entry.children
            .where((child) => widget.searchQuery?.value.isEmpty != false || child.isVisibleWithSearchQuery(widget.searchQuery!.value))
            .map((child) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: NierHierarchyEntry(entry: child, searchQuery: widget.searchQuery),
            )),
      ],
    );
  }
}

class _CollapsedIndicator extends StatelessWidget {
  final ValueNotifier<bool> isCollapsed;

  const _CollapsedIndicator({ super.key, required this.isCollapsed });

  @override
  Widget build(BuildContext context) {
    return OnHoverBuilder(
      builder: (context, isHovering) {
        var color = isHovering ? NierTheme.dark2 : NierTheme.brownDark;
        return Padding(
          padding: const EdgeInsets.all(2.0),
          child: InkWell(
            onTap: () => isCollapsed.value = !isCollapsed.value,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: color, width: 2.5),
                ),
              ),
              child: Center(
                child: Icon(
                  isCollapsed.value ? Icons.add : Icons.remove,
                  color: color,
                  size: 17,
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
