//
// Created by yangbin on 2022/1/27.
//

#ifndef MULTI_WINDOW_WINDOWS_BASE_FLUTTER_WINDOW_H_
#define MULTI_WINDOW_WINDOWS_BASE_FLUTTER_WINDOW_H_

#include "window_channel.h"

class BaseFlutterWindow {

 public:

  virtual ~BaseFlutterWindow() = default;

  virtual WindowChannel *GetWindowChannel() = 0;

  void Show();

  void Hide();

  void Close();

  void SetTitle(const std::string &title);

  void SetBounds(double_t x, double_t y, double_t width, double_t height);

  void Center();

  void HideTitleBar();

  void SetIgnoreMouseEvents(bool ignore);

  void SetBackgroundColor(int64_t backgroundColorA, int64_t backgroundColorR, int64_t backgroundColorG, int64_t backgroundColorB);

 protected:

  virtual HWND GetWindowHandle() = 0;

};

#endif //MULTI_WINDOW_WINDOWS_BASE_FLUTTER_WINDOW_H_
