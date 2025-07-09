# 图片缓存问题分析与解决方案

## 问题描述

推送ID `ce457473-5a36-11f0-ec4c-000107008c36` 推送成功后，展示的图片却是 `cde9c7e6-5a36-11f0-ec4c-00010700c70c` 的图片。

## 问题分析

### 1. 日志分析

从日志中可以看到：

1. **推送ID `ce457473-5a36-11f0-ec4c-000107008c36`** 在14:59:47被成功推送
   - 推送数据中的 `portraitImage.url` 应该是：`video_face_cropped/20250706-065948a39-0171e58fdd0e8d46-00000000-00004f75`

2. **但是图片加载的ID是 `cde9c7e6-5a36-11f0-ec4c-00010700c70c`**，这个ID在14:59:46就已经开始加载图片了
   - 推送数据中的 `portraitImage.url` 是：`video_face_cropped/20250706-065947a42-0171e58da86eb9f2-00000000-00001304`

### 2. 根本问题

**服务器端问题**：两个不同的 `objectId` 使用了相同的图片URL！

- `cde9c7e6-5a36-11f0-ec4c-00010700c70c` 使用：`video_face_cropped/20250706-065947a42-0171e58da86eb9f2-00000000-00001304`
- `ce457473-5a36-11f0-ec4c-000107008c36` 也使用：`video_face_cropped/20250706-065947a42-0171e58da86eb9f2-00000000-00001304`

但是根据推送数据，`ce457473-5a36-11f0-ec4c-000107008c36` 应该使用：`video_face_cropped/20250706-065948a39-0171e58fdd0e8d46-00000000-00004f75`

### 3. 客户端缓存问题

**SenseImage组件的缓存逻辑缺陷**：

```dart
// 原来的缓存逻辑（有问题）
if (_lastServerUrl != null &&
    _lastServerUrl == apiUrl &&
    _imageBytes != null) {
  // 服务器地址没有变化，且图片已加载，不需要重新加载
  return;
}
```

这个逻辑只检查了服务器地址是否变化，但没有检查 `objectKey` 是否变化。如果两个不同的 `objectId` 使用了相同的 `objectKey`（图片URL），那么第二个会使用第一个的缓存图片。

## 解决方案

### 1. 修复SenseImage组件的缓存逻辑

**修改前**：
```dart
class _SenseImageState extends State<SenseImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastServerUrl;
  final String _ts = DateTime.now().millisecondsSinceEpoch.toString();
```

**修改后**：
```dart
class _SenseImageState extends State<SenseImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastServerUrl;
  String? _lastObjectKey; // 添加objectKey缓存检查
  final String _ts = DateTime.now().millisecondsSinceEpoch.toString();
```

**修改缓存检查逻辑**：
```dart
// 检查服务器地址和objectKey是否发生变化
if (_lastServerUrl != null &&
    _lastServerUrl == apiUrl &&
    _lastObjectKey != null &&
    _lastObjectKey == widget.objectKey &&
    _imageBytes != null) {
  // 服务器地址和objectKey都没有变化，且图片已加载，不需要重新加载
  return;
}

_lastServerUrl = apiUrl;
_lastObjectKey = widget.objectKey; // 更新objectKey缓存
```

**添加objectKey变化检测**：
```dart
// 检查objectKey是否发生变化
if (_lastObjectKey != null && _lastObjectKey != widget.objectKey) {
  // objectKey发生变化，重新加载图片
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _loadImage();
    }
  });
}
```

### 2. 添加调试日志

在PhotoGallery中添加调试日志，记录每个推送数据的图片URL和objectId信息：

```dart
// 添加调试日志
_logger.info('[DEBUG] FaceCard构建: objectId=${pushData.objectId}, imageUrl=$imageUrl, name=$name, recordType=$recordType');
```

### 3. 创建测试脚本

创建 `test_image_cache.dart` 脚本来验证修复是否有效，测试两个不同objectId使用不同图片URL的情况。

## 验证方法

1. **运行修复后的应用**
2. **查看日志**，确认：
   - 每个objectId是否正确解析
   - 每个图片URL是否正确加载
   - SenseImage组件是否正确处理缓存

3. **运行测试脚本**：
   ```bash
   dart test_image_cache.dart
   ```

4. **检查应用日志**，确认：
   - 两个不同的objectId是否正确解析
   - 两个不同的图片URL是否正确加载
   - SenseImage组件是否正确处理缓存

## 预防措施

1. **服务器端检查**：确保每个objectId都有唯一的图片URL
2. **客户端缓存优化**：确保缓存逻辑正确，避免不同objectId使用相同图片URL时的冲突
3. **日志监控**：添加详细的调试日志，便于问题排查
4. **测试覆盖**：创建测试用例，覆盖各种边界情况

## 总结

这个问题的根本原因是服务器端数据混乱，导致两个不同的objectId使用了相同的图片URL。客户端SenseImage组件的缓存逻辑缺陷加剧了这个问题。

通过修复SenseImage组件的缓存逻辑，添加objectKey检查，可以确保即使服务器端出现问题，客户端也能正确处理图片显示。

同时，建议与服务器端开发人员沟通，确保每个objectId都有唯一的图片URL，从根本上解决这个问题。 