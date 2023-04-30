

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'stateManagement/dataInstances.dart';
import 'stateManagement/savableNotifier.dart';
import 'stateManagement/stages/stages.dart';
import 'utils/loggingWrapper.dart';
import 'widgets/stages/mainLayout.dart';
import 'widgets/theme/customTheme.dart';
import 'widgets/misc/mousePosition.dart';
import 'widgets/TitleBar/TitleBar.dart';

void main() {
  loggingWrapper(init);
}

void init() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(700, 400),
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    var windowPos = await windowManager.getPosition();
    if (windowPos.dy < 50)
      await windowManager.setPosition(windowPos.translate(0, 50));
    // await windowManager.focus();
  });
  SavableNotifier.init(await SharedPreferences.getInstance());
  initDataInstances();

  runApp(MyApp(stages: stages));
}

final _rootKey = GlobalKey<ScaffoldState>(debugLabel: "RootGlobalKey");

BuildContext getGlobalContext() => _rootKey.currentContext!;

class MyApp extends StatefulWidget {
  final Stages stages;

  const MyApp({ super.key, required this.stages });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nier Music Mod Manager",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: NierTheme.light,
        primaryColor: NierTheme.dark,
        textTheme: Theme.of(context).textTheme.apply(
          // fontFamily: "FiraCode",
          fontSizeFactor: 1.4,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: NierTheme.dark,
          selectionColor: NierTheme.brownLight,
          selectionHandleColor: NierTheme.brownDark,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(NierTheme.dark),
          thickness: MaterialStateProperty.all(5.5),
          thumbVisibility: MaterialStateProperty.all(true),
          radius: Radius.zero,
        ),
        colorScheme: const ColorScheme.light(
          primary: NierTheme.dark,
          secondary: NierTheme.brownDark,
        ),
      ),
      home: MyAppBody(key: _rootKey, stages: widget.stages,)
    );
  }
}

class MyAppBody extends StatelessWidget {
  final Stages stages;

  const MyAppBody({ super.key, required this.stages });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NierTheme.light,
      child: CustomPaint(
        foregroundPainter: const NierOverlayPainter(),
        child: MousePosition(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TitleBar(),
                  Expanded(child: MainLayout(stages: stages,)),
                ],
              ),
        ),
      ),
    );
  }
}
