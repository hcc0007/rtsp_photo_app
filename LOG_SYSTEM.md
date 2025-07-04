# 日志系统使用指南

本项目使用 `logging_flutter: ^3.0.0` 包实现了简化的日志管理系统。

## 功能特性

### 1. 多级别日志支持
- **FINEST**: 最详细的调试信息
- **FINER**: 较详细的调试信息  
- **FINE**: 调试信息
- **CONFIG**: 配置信息
- **INFO**: 一般信息
- **WARNING**: 警告信息
- **SEVERE**: 严重错误信息

### 2. 简化的日志界面
- 实时显示日志记录
- 日志统计信息
- 示例日志生成
- 清空日志功能

## 使用方法

### 基本使用

```dart
import 'package:logging/logging.dart';

// 创建Logger实例
final logger = Logger('MyModule');

// 记录不同级别的日志
logger.fine('调试信息');
logger.info('一般信息');
logger.warning('警告信息');
logger.severe('错误信息');
```

### 带错误和堆栈跟踪的日志

```dart
try {
  // 可能出错的代码
  throw Exception('模拟错误');
} catch (e, stackTrace) {
  logger.severe('操作失败', e, stackTrace);
}
```

### 在服务中使用

```dart
class MyService {
  final Logger _logger = Logger('MyService');
  
  void someMethod() {
    _logger.info('开始执行操作');
    // ... 业务逻辑
    _logger.info('操作完成');
  }
}
```

## 日志界面功能

### 1. 实时显示
- 自动捕获和显示所有日志记录
- 包含时间戳和日志级别

### 2. 示例日志
- 点击播放按钮生成示例日志
- 包含各种级别的日志示例

### 3. 清空功能
- 支持清空所有日志记录
- 带确认对话框

## 配置说明

### 依赖配置

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  logging_flutter: ^3.0.0
```

### 日志级别配置

```dart
// 设置Logger的级别
final logger = Logger('MyModule');
logger.level = Level.INFO; // 只显示INFO及以上级别的日志
```

## 最佳实践

### 1. 日志级别选择
- **FINEST/FINER/FINE**: 用于详细的调试信息
- **INFO**: 用于重要的业务操作
- **WARNING**: 用于潜在问题
- **SEVERE**: 用于严重错误

### 2. 日志内容
- 使用清晰、描述性的消息
- 包含必要的上下文信息
- 避免记录敏感信息

### 3. 性能考虑
- 避免在循环中记录大量日志
- 使用条件日志记录
- 定期清理旧日志

## 注意事项

1. 日志系统会自动限制内存中的日志数量（最多500条）
2. 生产环境建议设置合适的日志级别
3. 敏感信息不应记录在日志中
4. 使用 `logging_flutter` 包简化了日志管理，无需额外的Provider

## 优势

- **简化架构**: 无需自定义LogProvider
- **内置UI**: logging_flutter提供完整的日志界面
- **易于使用**: 直接使用标准的logging包API
- **性能优化**: 自动管理内存使用 