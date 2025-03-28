import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_multi_window_example/applog.dart';

class ToolbarWindow extends StatefulWidget {
  final int windowId;
  final int popupWindowId;
  final Offset initialPostion; // 记录窗口初始位置
  final double width;
  final double height;

  const ToolbarWindow(
      {Key? key,
      required this.windowId,
      required this.popupWindowId,
      required this.initialPostion,
      required this.width,
      required this.height})
      : super(key: key);

  @override
  _ToolbarWindowState createState() => _ToolbarWindowState();
}

class _ToolbarWindowState extends State<ToolbarWindow> {
  late WindowController _windowController;
  Offset _initialPosition = Offset.zero; // 记录窗口初始位置
  Offset _dragStart = Offset.zero; // 记录鼠标拖动起点
  Offset _totalDisplacement = Offset.zero;
  int _buttonState = 0;

  @override
  void initState() {
    super.initState();
    _windowController = WindowController.fromWindowId(widget.windowId);

    _initialPosition = widget.initialPostion;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent, // 透明背景
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent, // 关键：Scaffold 透明
        body: GestureDetector(
          onPanStart: (details) {
            _dragStart = details.globalPosition; // 记录起点
            _totalDisplacement = Offset.zero; // 重置累加器
          },
          onPanUpdate: (details) async {
            try {
              Offset delta = details.globalPosition - _dragStart;
              _totalDisplacement += delta; // 累加位移

              // 计算新位置
              Offset newPosition = _initialPosition + delta;

              // 延迟更新窗口位置（避免卡顿）
              Future.delayed(Duration.zero, () async {
                await _windowController.setFrame(
                  Rect.fromLTWH(newPosition.dx, newPosition.dy, widget.width,
                      widget.height),
                );
              });

              _initialPosition = newPosition; // 更新存储的位置
            } catch (e) {
              AppLogger.log('窗口位置更新失败: $e');
            }
          },
          onPanEnd: (details) {
            if (_totalDisplacement.distance > 0) {
              removeWindow(_totalDisplacement);
            }
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '拖拽窗口\nWindow ID: ${widget.windowId}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_buttonState == 0) {
                        _buttonState = 1; // 从未选中变为选中
                      } else if (_buttonState == 1) {
                        _buttonState = 2; // 从选中变为激活状态
                        popup("test"); // 调用激活方法
                      } else {
                        _buttonState = 0; // 重置状态
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _buttonState == 0
                          ? Colors.grey
                          : _buttonState == 1
                              ? Colors.blue
                              : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _buttonState == 0
                          ? Icons.circle_outlined
                          : _buttonState == 1
                              ? Icons.check_circle_outline
                              : Icons.check_circle,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void popup(String popupType) async {
    final result = await DesktopMultiWindow.invokeMethod(
        widget.popupWindowId, "popup", popupType);
    debugPrint("popUp result: $result");
  }

  void removeWindow(Offset displacement) async {
    Map<String, dynamic> args = {
      'dx': displacement.dx,
      'dy': displacement.dy,
    };
    final result = await DesktopMultiWindow.invokeMethod(
        widget.popupWindowId, "removeWindow", args);
    debugPrint("removeWindow result: $result");
  }
}
