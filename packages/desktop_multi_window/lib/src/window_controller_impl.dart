import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'channels.dart';
import 'window_controller.dart';

class WindowControllerMainImpl extends WindowController {
  final MethodChannel _channel = multiWindowChannel;

  // the id of this window
  final int _id;

  WindowControllerMainImpl(this._id);

  @override
  int get windowId => _id;

  @override
  Future<void> close() {
    return _channel.invokeMethod('close', _id);
  }

  @override
  Future<void> hide() {
    return _channel.invokeMethod('hide', _id);
  }

  @override
  Future<void> show() {
    return _channel.invokeMethod('show', _id);
  }

  @override
  Future<void> center() {
    return _channel.invokeMethod('center', _id);
  }

  @override
  Future<void> hideTitleBar() {
    return _channel.invokeMethod('hideTitleBar', _id);
  }

  @override
  Future<void> setIgnoreMouseEvents(bool ignore) {
    return _channel.invokeMethod('setIgnoreMouseEvents', <String, dynamic>{
      'windowId': _id,
      'ignore': ignore,
    });
  }

  @override
  Future<void> setBackgroundColor(Color backgroundColor) {
    return _channel.invokeMethod('setBackgroundColor', <String, dynamic>{
      'windowId': _id,
      'backgroundColorA': (backgroundColor.a * 255).round(),
      'backgroundColorR': (backgroundColor.r * 255).round(),
      'backgroundColorG': (backgroundColor.g * 255).round(),
      'backgroundColorB': (backgroundColor.b * 255).round(),
    });
  }

  @override
  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) {
    return _channel.invokeMethod('setAlwaysOnTop', <String, dynamic>{
      'windowId': _id,
      'isAlwaysOnTop': isAlwaysOnTop,
    });
  }

  @override
  Future<void> setFrame(Rect frame) {
    return _channel.invokeMethod('setFrame', <String, dynamic>{
      'windowId': _id,
      'left': frame.left,
      'top': frame.top,
      'width': frame.width,
      'height': frame.height,
    });
  }

  @override
  Future<void> setTitle(String title) {
    return _channel.invokeMethod('setTitle', <String, dynamic>{
      'windowId': _id,
      'title': title,
    });
  }

  @override
  Future<void> resizable(bool resizable) {
    if (Platform.isMacOS) {
      return _channel.invokeMethod('resizable', <String, dynamic>{
        'windowId': _id,
        'resizable': resizable,
      });
    } else {
      throw MissingPluginException(
        'This functionality is only available on macOS',
      );
    }
  }

  @override
  Future<void> setFrameAutosaveName(String name) {
    return _channel.invokeMethod('setFrameAutosaveName', <String, dynamic>{
      'windowId': _id,
      'name': name,
    });
  }
}
