# 节拍器

Flutter 节拍器和调音器应用。

## 功能

### 节拍器
- BPM 控制（20-300）
- Tap tempo 敲击测速
- 节拍类型（2/4, 3/4, 4/4, 5/4, 6/8, 7/8）
- 细分音（四分音符, 八分音符, 三连音, 十六分音符）
- 多种音色（滴答, 木块, 电子）
- 预设保存/读取
- 练习模式（渐进/静音模式）

### 调音器
- 实时音高检测
- 参考音生成（A4 = 440Hz 可调节）
- 弦乐器快速调音

## 命令

```bash
flutter pub get          # 安装依赖
flutter run              # 运行应用
flutter test             # 运行测试
flutter analyze          # 静态分析
flutter format lib/      # 格式化代码
flutter build apk        # 构建 Android APK
flutter build ios        # 构建 iOS 应用
```

## 架构

- `lib/main.dart` — 入口，音频服务初始化
- `lib/app.dart` — 根组件，MaterialApp 配置
- `lib/models/` — 数据模型（枚举、状态、预设、音符）
- `lib/notifiers/` — 状态管理（节拍器、调音器）
- `lib/services/` — 音频处理、预设存储、音频池
- `lib/ui/screens/` — 主页面（节拍器、调音器）
- `lib/ui/widgets/` — 可复用 UI 组件
- `lib/core/` — 常量和乐理数值

状态管理使用 `ChangeNotifier` 模式。音频使用 `audio_service` 包实现后台播放。