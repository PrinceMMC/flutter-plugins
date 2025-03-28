// #region 弹出透明背景可移动的窗体
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_multi_window_example/popup_window.dart';
import 'package:flutter_multi_window_example/toolbar_window.dart';
import 'package:screen_retriever/screen_retriever.dart';

void main(List<String> args) async {
  // WidgetsFlutterBinding.ensureInitialized();

  if (args.isEmpty || args[0] != 'multi_window') {
    runApp(MyApp());
  } else {
    final windowId = int.parse(args[1]);
    Map<String, dynamic> arguments = json.decode(args[2]);
    if (arguments["name"] == "toolbar") {
      runApp(ToolbarWindow(
          windowId: windowId,
          popupWindowId: arguments["popupWindowId"],
          initialPostion: Offset(
              arguments["window_frame_left"], arguments["window_frame_top"]),
          width: arguments["window_frame_width"],
          height: arguments["window_frame_height"]));
    } else if (arguments["name"] == "popup") {
      runApp(
        MaterialApp(
          home: PopupWindow(
              windowId: windowId,
              initialPostion: Offset(arguments["window_frame_left"],
                  arguments["window_frame_top"]),
              width: arguments["window_frame_width"],
              height: arguments[
                  "window_frame_height"]), // 确保 NewWindowApp 是 MaterialApp 的子组件
        ),
      );
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Main Window')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await createNewWindow();
            },
            child: Text('Open New Window'),
          ),
        ),
      ),
    );
  }
}

// class NewWindowApp extends StatefulWidget {
//   final int windowId;

//   const NewWindowApp({Key? key, required this.windowId}) : super(key: key);

//   @override
//   _NewWindowAppState createState() => _NewWindowAppState();
// }

// class _NewWindowAppState extends State<NewWindowApp> {
//   late WindowController _windowController;
//   Offset _initialPosition = Offset.zero; // 记录窗口初始位置
//   Offset _dragStart = Offset.zero; // 记录鼠标拖动起点

//   @override
//   void initState() {
//     super.initState();
//     _windowController = WindowController.fromWindowId(widget.windowId);

//     _initialPosition = Offset(100, 100); // 设定窗口初始位置
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: Colors.transparent, // 透明背景
//       ),
//       home: Scaffold(
//         backgroundColor: Colors.transparent, // 关键：Scaffold 透明
//         body: GestureDetector(
//           onPanStart: (details) {
//             _dragStart = details.globalPosition; // 记录拖拽起点
//           },
//           onPanUpdate: (details) async {
//             try {
//               // 计算拖动的相对位移
//               Offset newPosition =
//                   _initialPosition + (details.globalPosition - _dragStart);

//               // 更新窗口位置（加个 Future.delayed 避免卡顿）
//               Future.delayed(Duration.zero, () async {
//                 await _windowController.setFrame(
//                   Rect.fromLTWH(newPosition.dx, newPosition.dy, 400, 300),
//                 );
//               });

//               // 更新当前存储的窗口位置
//               _initialPosition = newPosition;
//             } catch (e) {
//               AppLogger.log('onPanUpdate 设置窗口位置失败: $e');
//             }
//           },
//           onPanEnd: (details) {
//             //在这发数据？这样不用两个窗口实时动，性能可能会好一些
//           },
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.pink, // 半黑背景（仅控件区域）
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(
//                 '拖拽窗口\nWindow ID: ${widget.windowId}',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

Future<void> createNewWindow() async {
  // 获取主显示器的工作区域
  final display = await screenRetriever.getPrimaryDisplay();

  // 获取屏幕工作区域大小
  final screenWidth = display.visibleSize!.width;
  final screenHeight = display.visibleSize!.height;

  const toolBarWidth = 400.0;
  const toolBarHeight = 300.0;

  const popupWidth = 400.0;
  const popupHeight = 300.0;

  // 计算工具栏窗口位置（确保使用浮点数运算）
  final toolBarleft = max(0.0, (screenWidth - toolBarWidth) / 2.0);
  final toolBartop = max(0.0, screenHeight - toolBarHeight - 50);

  // 计算弹窗窗口位置（确保使用浮点数运算）
  final popupleft = max(0.0, (screenWidth - popupWidth) / 2.0);
  final popuptop = max(0.0, screenHeight - popupHeight - 50 - toolBarHeight);

  // 定义Map并转为JSON字符串
  Map<String, dynamic> popupParams = {
    'name': 'popup',
    'window_frame_left': popupleft,
    'window_frame_top': popuptop,
    'window_frame_width': popupWidth,
    'window_frame_height': popupHeight,
  };
  final popupArguments = json.encode(popupParams);
  final popupWindow = await DesktopMultiWindow.createWindow(popupArguments);
  await popupWindow.setTitle('New Window');
  final popupRect = Rect.fromLTWH(popupleft, popuptop, popupWidth, popupHeight);
  await popupWindow.setFrame(popupRect);
  await popupWindow.setBackgroundColor(Colors.transparent);
  await popupWindow.setAlwaysOnTop(true);
  await popupWindow.hideTitleBar();
  await popupWindow.show();

  // 定义Map并转为JSON字符串
  Map<String, dynamic> toolBarParams = {
    'name': 'toolbar',
    'popupWindowId': popupWindow.windowId,
    'window_frame_left': toolBarleft,
    'window_frame_top': toolBartop,
    'window_frame_width': toolBarWidth,
    'window_frame_height': toolBarHeight,
  };
  final toolBarArguments = json.encode(toolBarParams);

  final window = await DesktopMultiWindow.createWindow(toolBarArguments);
  await window.setTitle('New Window');
  final toolBarRect =
      Rect.fromLTWH(toolBarleft, toolBartop, toolBarWidth, toolBarHeight);
  await window.setFrame(toolBarRect);
  // await window.setIgnoreMouseEvents(true);
  await window.setBackgroundColor(Colors.transparent);
  await window.setAlwaysOnTop(true);
  await window.hideTitleBar();
  await window.show();

  // final pop = await DesktopMultiWindow.createWindow('new_window');
} 

// #endregion



// #region 官方例子 主要是多窗口间通讯
// import 'dart:convert';

// import 'package:collection/collection.dart';
// import 'package:desktop_lifecycle/desktop_lifecycle.dart';
// import 'package:desktop_multi_window/desktop_multi_window.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_multi_window_example/event_widget.dart';

// void main(List<String> args) {
//   if (args.firstOrNull == 'multi_window') {
//     final windowId = int.parse(args[1]);
//     final argument = args[2].isEmpty
//         ? const {}
//         : jsonDecode(args[2]) as Map<String, dynamic>;
//     runApp(_ExampleSubWindow(
//       windowController: WindowController.fromWindowId(windowId),
//       args: argument,
//     ));
//   } else {
//     runApp(const _ExampleMainWindow());
//   }
// }

// class _ExampleMainWindow extends StatefulWidget {
//   const _ExampleMainWindow({Key? key}) : super(key: key);

//   @override
//   State<_ExampleMainWindow> createState() => _ExampleMainWindowState();
// }

// class _ExampleMainWindowState extends State<_ExampleMainWindow> {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         body: Column(
//           children: [
//             TextButton(
//               onPressed: () async {
//                 final window =
//                     await DesktopMultiWindow.createWindow(jsonEncode({
//                   'args1': 'Sub window',
//                   'args2': 100,
//                   'args3': true,
//                   'business': 'business_test',
//                 }));
//                 window
//                   ..setFrame(const Offset(0, 0) & const Size(1280, 720))
//                   ..center()
//                   ..setTitle('Another window')
//                   ..show();
//               },
//               child: const Text('Create a new World!'),
//             ),
//             TextButton(
//               child: const Text('Send event to all sub windows'),
//               onPressed: () async {
//                 final subWindowIds =
//                     await DesktopMultiWindow.getAllSubWindowIds();
//                 for (final windowId in subWindowIds) {
//                   DesktopMultiWindow.invokeMethod(
//                     windowId,
//                     'broadcast',
//                     'Broadcast from main window',
//                   );
//                 }
//               },
//             ),
//             Expanded(
//               child: EventWidget(controller: WindowController.fromWindowId(0)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ExampleSubWindow extends StatelessWidget {
//   const _ExampleSubWindow({
//     Key? key,
//     required this.windowController,
//     required this.args,
//   }) : super(key: key);

//   final WindowController windowController;
//   final Map? args;

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Plugin example app'),
//         ),
//         body: Column(
//           children: [
//             if (args != null)
//               Text(
//                 'Arguments: ${args.toString()}',
//                 style: const TextStyle(fontSize: 20),
//               ),
//             ValueListenableBuilder<bool>(
//               valueListenable: DesktopLifecycle.instance.isActive,
//               builder: (context, active, child) {
//                 if (active) {
//                   return const Text('Window Active');
//                 } else {
//                   return const Text('Window Inactive');
//                 }
//               },
//             ),
//             TextButton(
//               onPressed: () async {
//                 windowController.close();
//               },
//               child: const Text('Close this window'),
//             ),
//             Expanded(child: EventWidget(controller: windowController)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// #endregion

// import 'package:flutter/material.dart';
// import 'package:desktop_lifecycle/desktop_lifecycle.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Custom Popup with Desktop Lifecycle'),
//         ),
//         body: Center(
//           child: PopupButton(),
//         ),
//       ),
//     );
//   }
// }





// class PopupButton extends StatefulWidget {
//   @override
//   _PopupButtonState createState() => _PopupButtonState();
// }

// class _PopupButtonState extends State<PopupButton> {
//   OverlayEntry? _overlayEntry;

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<bool>(
//       valueListenable: DesktopLifecycle.instance.isActive,
//       builder: (context, isActive, child) {
//         // 当窗口失去焦点时，关闭弹窗
//         if (!isActive && _overlayEntry != null) {
//           _overlayEntry!.remove();
//           _overlayEntry = null;
//         }

//         return ElevatedButton(
//           onPressed: () {
//             _showCustomPopup(context);
//           },
//           child: Text('Show Custom Popup'),
//         );
//       },
//     );
//   }

//   void _showCustomPopup(BuildContext context) {
//     // 使用 Overlay 实现自定义弹框
//     OverlayState overlayState = Overlay.of(context);
//     _overlayEntry = OverlayEntry(
//       builder: (context) {
//         // 自定义弹框内容
//         return Stack(
//           children: [
//             // 透明遮罩（可选）
//             GestureDetector(
//               onTap: () {
//                 // 点击遮罩关闭弹框
//                 _overlayEntry?.remove();
//                 _overlayEntry = null;
//               },
//               child: Container(
//                 color: Colors.transparent, // 透明遮罩
//               ),
//             ),
//             // 自定义弹框位置
//             Positioned(
//               top: 100, // 弹框距离顶部的距离
//               left: 100, // 弹框距离左侧的距离
//               child: Material(
//                 color: Colors.transparent,
//                 child: Container(
//                   width: 300,
//                   height: 200,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('This is a custom popup.'),
//                       SizedBox(height: 20),
//                       ElevatedButton(
//                         onPressed: () {
//                           _overlayEntry?.remove(); // 关闭弹框
//                           _overlayEntry = null;
//                         },
//                         child: Text('Close'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     // 将弹框添加到 Overlay
//     overlayState.insert(_overlayEntry!);
//   }

//   @override
//   void dispose() {
//     _overlayEntry?.remove();
//     super.dispose();
//   }
// }