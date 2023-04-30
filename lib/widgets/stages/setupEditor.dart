
import 'package:flutter/material.dart';

import '../../stateManagement/dataInstances.dart';
import '../../stateManagement/stages/setup.dart';
import '../misc/SmoothScrollBuilder.dart';
import '../theme/NierButton.dart';
import '../theme/NierButtonFancy.dart';
import '../theme/NierTextField.dart';

class PathsEditor extends StatefulWidget {
  final StageSetup stage;

  const PathsEditor({ super.key, required this.stage });

  @override
  State<PathsEditor> createState() => _PathsEditorState();
}

class _PathsEditorState extends State<PathsEditor> {
  final scrollController = ScrollController();
  late final TextEditingController gameDataPathController;
  late final TextEditingController workingDirController;

  @override
  void initState() {
    super.initState();
    gameDataPathController = TextEditingController(text: widget.stage.gameDataDir.value);
    workingDirController = TextEditingController(text: widget.stage.workingDir.value);
    // gameDataPathController.addListener(_onGameDataPathChanged);
    // workingDirController.addListener(_onWorkingDirChanged);
  }

  Future<void> _loadFiles() async {
    setState(() => statusInfo.isBusy.value = true);
    try {
      await widget.stage.loadFiles();
    } finally {
      setState(() => statusInfo.isBusy.value = false);
    }
  }

  void _onGameDataPathChanged() {
    widget.stage.gameDataDir.value = gameDataPathController.text;
  }

  void _onWorkingDirChanged() {
    widget.stage.workingDir.value = workingDirController.text;
  }

  @override
  Widget build(BuildContext context) {
    return SmoothSingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Game Path"),
          const SizedBox(height: 8),
          NierTextField(
            controller: gameDataPathController,
            width: 500,
            onChanged: (value) => _onGameDataPathChanged(),
          ),
          const SizedBox(height: 8),
          NierButton(
            text: "Select Game Path",
            icon: Icons.folder_open,
            onPressed: () => widget.stage.selectGameDataPath()
              .then((_) {
                gameDataPathController.text = widget.stage.gameDataDir.value;
              }),
            width: 310,
          ),
          const SizedBox(height: 16),
          const Text("Working Directory"),
          const SizedBox(height: 8),
          NierTextField(
            controller: workingDirController,
            width: 500,
            onChanged: (value) => _onWorkingDirChanged(),
          ),
          const SizedBox(height: 8),
          NierButton(
            text: "Select Working Directory",
            icon: Icons.folder_open,
            onPressed: () => widget.stage.selectWorkingDir()
              .then((_) {
                workingDirController.text = widget.stage.workingDir.value;
              }),
            width: 310,
          ),
          const SizedBox(height: 16),
          NierButton(
              onPressed: statusInfo.isBusy.value ? null : _loadFiles,
              text: widget.stage.hasLoaded.value ? "Reload files" : "Load files"
          ),
        ],
      ),
    );
  }
}
