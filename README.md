# ScreenScale16 safe rebuild

Based on the known-working 96%/34pt implementation.

Safety changes:
- no private allWindowsIncludingInternalWindows enumeration
- no UIWindow.layer.transform
- no scene activation-state broadening
- root UIRootSceneWindow keeps the existing scale + 34pt crop
- status-bar windows get scale only, never crop
- other SpringBoard windows are scaled only when they are full-display sized
- keyboard/input windows remain excluded

Target: iOS 16, RootHide/Dopamine, arm64e.
