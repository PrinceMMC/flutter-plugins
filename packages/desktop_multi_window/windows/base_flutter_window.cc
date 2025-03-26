//
// Created by yangbin on 2022/1/27.
//

#include "base_flutter_window.h"

namespace {
void CenterRectToMonitor(LPRECT prc) {
  HMONITOR hMonitor;
  MONITORINFO mi;
  RECT rc;
  int w = prc->right - prc->left;
  int h = prc->bottom - prc->top;

  //
  // get the nearest monitor to the passed rect.
  //
  hMonitor = MonitorFromRect(prc, MONITOR_DEFAULTTONEAREST);

  //
  // get the work area or entire monitor rect.
  //
  mi.cbSize = sizeof(mi);
  GetMonitorInfo(hMonitor, &mi);

  rc = mi.rcMonitor;

  prc->left = rc.left + (rc.right - rc.left - w) / 2;
  prc->top = rc.top + (rc.bottom - rc.top - h) / 2;
  prc->right = prc->left + w;
  prc->bottom = prc->top + h;

}

std::wstring Utf16FromUtf8(const std::string &string) {
  int size_needed = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), -1, nullptr, 0);
  if (size_needed == 0) {
    return {};
  }
  std::wstring wstrTo(size_needed, 0);
  int converted_length = MultiByteToWideChar(CP_UTF8, 0, string.c_str(), -1, &wstrTo[0], size_needed);
  if (converted_length == 0) {
    return {};
  }
  return wstrTo;
}

}

void BaseFlutterWindow::Center() {
  auto handle = GetWindowHandle();
  if (!handle) {
    return;
  }
  RECT rc;
  GetWindowRect(handle, &rc);
  CenterRectToMonitor(&rc);
  SetWindowPos(handle, nullptr, rc.left, rc.top, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}

void BaseFlutterWindow::SetBounds(double_t x, double_t y, double_t width, double_t height) {
  auto handle = GetWindowHandle();
  if (!handle) {
    return;
  }
  MoveWindow(handle, int32_t(x), int32_t(y),
             static_cast<int>(width),
             static_cast<int>(height),
             TRUE);
}

void BaseFlutterWindow::SetTitle(const std::string &title) {
  auto handle = GetWindowHandle();
  if (!handle) {
    return;
  }
  SetWindowText(handle, Utf16FromUtf8(title).c_str());
}

void BaseFlutterWindow::Close() {
  auto handle = GetWindowHandle();
  if (!handle) {
    return;
  }
  PostMessage(handle, WM_SYSCOMMAND, SC_CLOSE, 0);
}

void BaseFlutterWindow::Show() {
  auto handle = GetWindowHandle();
  if (!handle) {
    return;
  }
  ShowWindow(handle, SW_SHOW);

}

void BaseFlutterWindow::Hide() {
  auto handle = GetWindowHandle();
  if (!handle) {
    return;
  }
  ShowWindow(handle, SW_HIDE);
}

void BaseFlutterWindow::HideTitleBar() {
    auto handle = GetWindowHandle();
    if (!handle) {
        return;
    }
    
    LONG_PTR style = GetWindowLongPtr(handle, GWL_STYLE);
    if (style == 0) {
        return;
    }

    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);

    SetWindowLongPtr(handle, GWL_STYLE, style);

    SetWindowPos(handle, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

void BaseFlutterWindow::SetIgnoreMouseEvents(bool ignore) {
    auto handle = GetWindowHandle();
    if (!handle) {
        return;
    }
    
    LONG_PTR ex_style = GetWindowLongPtr(handle, GWL_EXSTYLE);
    if (ignore)
      ex_style |= WS_EX_TRANSPARENT;
    else
      ex_style &= ~WS_EX_TRANSPARENT;

    SetWindowLongPtr(handle, GWL_EXSTYLE, ex_style);

    SetWindowPos(handle, nullptr, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

void BaseFlutterWindow::SetBackgroundColor(int64_t backgroundColorA, int64_t backgroundColorR, int64_t backgroundColorG, int64_t backgroundColorB)
{
    auto handle = GetWindowHandle();
    if (!handle)
    {
        return;
    }

    bool isTransparent = backgroundColorA == 0 && backgroundColorR == 0 &&
                         backgroundColorG == 0 && backgroundColorB == 0;

    const HINSTANCE hModule = LoadLibrary(TEXT("user32.dll"));
    if (hModule)
    {
        typedef enum _ACCENT_STATE
        {
            ACCENT_DISABLED = 0,
            ACCENT_ENABLE_GRADIENT = 1,
            ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
            ACCENT_ENABLE_BLURBEHIND = 3,
            ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
            ACCENT_ENABLE_HOSTBACKDROP = 5,
            ACCENT_INVALID_STATE = 6
        } ACCENT_STATE;
        struct ACCENTPOLICY
        {
            int nAccentState;
            int nFlags;
            int nColor; 
            int nAnimationId;
        };
        struct WINCOMPATTRDATA
        {
            int nAttribute;
            PVOID pData;
            ULONG ulDataSize;
        };
        typedef BOOL(WINAPI * pSetWindowCompositionAttribute)(HWND,
                                                              WINCOMPATTRDATA *);
        const pSetWindowCompositionAttribute SetWindowCompositionAttribute =
            (pSetWindowCompositionAttribute)GetProcAddress(
                hModule, "SetWindowCompositionAttribute");
        if (SetWindowCompositionAttribute)
        {
            int32_t accent_state = isTransparent ? ACCENT_ENABLE_TRANSPARENTGRADIENT
                                                 : ACCENT_ENABLE_GRADIENT;

           
            int color = static_cast<int>(
                ((backgroundColorA & 0xFF) << 24) | 
                ((backgroundColorB & 0xFF) << 16) | 
                ((backgroundColorG & 0xFF) << 8) |  
                (backgroundColorR & 0xFF)           
            );

            ACCENTPOLICY policy = {accent_state, 2, color, 0};
            WINCOMPATTRDATA data = {19, &policy, sizeof(policy)};
            SetWindowCompositionAttribute(handle, &data);
        }
        FreeLibrary(hModule);
    }
}