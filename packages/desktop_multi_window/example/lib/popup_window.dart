import 'dart:convert';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_window_example/event_widget.dart'
    show MessageItem;

import 'applog.dart' show AppLogger;

class PopupWindow extends StatefulWidget {
  const PopupWindow(
      {Key? key,
      required this.windowId,
      required this.initialPostion,
      required this.width,
      required this.height})
      : super(key: key);

  final int windowId;
  final Offset initialPostion; // 记录窗口初始位置
  final double width;
  final double height;

  @override
  State<PopupWindow> createState() => PopupWindowState();
}

class PopupWindowState extends State<PopupWindow> {
  late WindowController _windowController;
  late Offset _currentPosition; // 真正的可变值放在State里
  final messages = <MessageItem>[];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _windowController = WindowController.fromWindowId(widget.windowId);
    _currentPosition = widget.initialPostion;
    DesktopMultiWindow.setMethodHandler(_handleMethodCallback);
  }

  @override
  dispose() {
    DesktopMultiWindow.setMethodHandler(null);
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<dynamic> _handleMethodCallback(
      MethodCall call, int fromWindowId) async {
    // 使用
    AppLogger.log("fromWindowId:$fromWindowId Call:$call");
    if (call.method == "removeWindow") {
      double dx = call.arguments["dx"];
      double dy = call.arguments["dy"];
      //此处需跟随移动
      await removeWindow(dx, dy);
    } else if (call.method == "popup") {
      showCustomPopup();
    }
  }

  Future<void> removeWindow(double dx, double dy) async {
    try {
      Offset delta = Offset(dx, dy);
      // 计算新位置
      Offset newPosition = _currentPosition + delta;

      // 延迟更新窗口位置（避免卡顿）
      Future.delayed(Duration.zero, () async {
        await _windowController.setFrame(
          Rect.fromLTWH(
              newPosition.dx, newPosition.dy, widget.width, widget.height),
        );
      });

      _currentPosition = newPosition;
    } catch (e) {
      AppLogger.log('onPanUpdate 设置窗口位置失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(color: Colors.transparent),
            ValueListenableBuilder<bool>(
              valueListenable: DesktopLifecycle.instance.isActive,
              builder: (context, isActive, child) {
                if (!isActive && _overlayEntry != null) {
                  _overlayEntry?.remove();
                  _overlayEntry = null;
                }
                return const SizedBox();
              },
            ),
            // 添加一个隐藏的按钮用于测试弹窗
            Positioned(
              bottom: 20,
              right: 20,
              child: Opacity(
                opacity: 1, // 几乎不可见，仅用于测试
                child: TextButton(
                  onPressed: showCustomPopup,
                  child: Text('Show Popup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showCustomPopup() {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 阻止内容点击冒泡
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('弹窗内容', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        _overlayEntry?.remove();
                        _overlayEntry = null;
                      },
                      child: Text('关闭'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_overlayEntry!);
  }
}
