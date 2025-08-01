# 自动登录功能使用指南

## 功能概述

应用现在支持自动登录功能，具体行为如下：

1. **有Token时**：应用启动时会自动尝试登录，如果登录成功，用户将直接进入已登录状态
2. **无Token时**：应用启动时跳过自动登录，用户需要手动登录
3. **登录失败**：即使自动登录失败，也不会阻塞页面进入，用户可以正常使用应用

## 功能特点

### 1. 智能Token检测
- 应用启动时自动检查本地存储的token
- 如果token存在且不为空，则尝试自动登录
- 如果token不存在或为空，则跳过自动登录

### 2. 非阻塞式登录
- 自动登录过程不会阻塞UI界面
- 用户可以在登录过程中正常使用应用
- 登录失败不会影响应用的正常启动

### 3. 状态可视化
- 在应用顶部显示登录状态指示器
- 绿色表示已登录，橙色表示未登录
- 登录按钮会根据登录状态显示不同图标

### 4. 用户友好的界面
- 已登录时：点击用户图标显示用户信息
- 未登录时：点击登录图标显示登录对话框
- 登出按钮只在已登录时显示

## 使用流程

### 首次使用
1. 启动应用
2. 应用检测到无token，跳过自动登录
3. 点击登录按钮进行手动登录
4. 登录成功后，token会被保存到本地

### 后续使用
1. 启动应用
2. 应用检测到有token，自动尝试登录
3. 如果登录成功，用户直接进入已登录状态
4. 如果登录失败，用户仍可正常使用应用，并可手动重新登录

## 技术实现

### 核心组件

1. **AppInitializer** (`lib/widgets/app_initializer.dart`)
   - 负责应用启动时的初始化逻辑
   - 检查token并决定是否执行自动登录

2. **AuthProvider** (`lib/providers/auth_provider.dart`)
   - 管理认证状态
   - 提供自动登录和手动登录方法

3. **AuthService** (`lib/services/auth_service.dart`)
   - 处理具体的登录逻辑
   - 管理token和用户信息

4. **AppConfig** (`lib/config/app_config.dart`)
   - 管理本地存储的配置信息
   - 包括token、用户名、密码等

### 关键方法

```dart
// 自动登录方法
Future<bool> autoLogin() async {
  // 检查是否已登录
  if (_isLoggedIn) return true;
  
  // 执行登录逻辑
  final result = await _authService.login(
    account: username,
    password: password,
  );
  
  // 处理登录结果
  if (result['success']) {
    _isLoggedIn = true;
    _startTokenRefreshTimer();
    return true;
  }
  
  return false;
}
```

## 配置说明

### Token存储
- Token存储在本地SharedPreferences中
- 键名：`token`
- 登录成功后自动保存
- 登出时自动清除

### 自动登录配置
- 在`AppInitializer`中配置自动登录逻辑
- 可以通过修改`_attemptAutoLogin`方法来自定义自动登录行为
- 登录超时时间固定为30秒

## 注意事项

1. **网络连接**：自动登录需要网络连接，如果网络不可用，登录会失败但不影响应用使用
2. **登录超时**：登录请求有超时限制（30秒），超时后会显示相应错误信息
3. **Token过期**：如果token已过期，自动登录会失败，用户需要重新手动登录
4. **安全性**：token存储在本地，请确保设备安全
5. **用户体验**：自动登录失败时，应用会显示相应的错误信息，但不会阻塞用户操作

## 故障排除

### 自动登录失败
1. 检查网络连接
2. 检查服务器地址和端口配置
3. 检查用户名和密码是否正确
4. 查看应用日志获取详细错误信息

### Token相关问题
1. 清除应用数据重新登录
2. 检查token是否已过期
3. 确认服务器端token验证逻辑

## 更新日志

- **v1.0.0**: 实现基础自动登录功能
- 支持token检测和自动登录
- 添加登录状态可视化
- 实现非阻塞式登录流程 