# 免费构建Android APK指南

## 方案1：GitHub Actions（推荐）

### 步骤1：创建GitHub仓库
1. 访问 https://github.com
2. 点击 "New repository"
3. 输入仓库名称，如 `rtsp-photo-app`
4. 选择 "Public"（免费用户推荐）
5. 点击 "Create repository"

### 步骤2：上传代码
```bash
# 在项目目录中执行
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/rtsp-photo-app.git
git push -u origin main
```

### 步骤3：触发构建
1. 在GitHub仓库页面，点击 "Actions" 标签
2. 选择 "Manual Build APK" 工作流
3. 点击 "Run workflow" 按钮
4. 等待构建完成（约5-10分钟）

### 步骤4：下载APK
1. 构建完成后，点击构建记录
2. 在 "Artifacts" 部分下载 `rtsp-photo-app-release.zip`
3. 解压后得到 `app-release.apk` 文件

## 方案2：Codemagic（免费额度）

### 步骤1：注册Codemagic
1. 访问 https://codemagic.io
2. 使用GitHub账号注册
3. 免费用户每月有500分钟构建时间

### 步骤2：连接仓库
1. 点击 "Add application"
2. 选择您的GitHub仓库
3. 选择Flutter项目

### 步骤3：配置构建
Codemagic会自动检测Flutter项目，无需额外配置

### 步骤4：构建APK
1. 点击 "Start new build"
2. 选择 "Android" 平台
3. 等待构建完成

## 方案3：Bitrise（免费额度）

### 步骤1：注册Bitrise
1. 访问 https://bitrise.io
2. 使用GitHub账号注册
3. 免费用户每月有200分钟构建时间

### 步骤2：添加应用
1. 点击 "Add new app"
2. 选择GitHub仓库
3. 选择 "Flutter" 项目类型

### 步骤3：构建APK
1. 使用默认的Flutter工作流
2. 点击 "Start a new build"
3. 等待构建完成

## 方案4：GitLab CI（免费）

如果您使用GitLab，可以创建 `.gitlab-ci.yml` 文件：

```yaml
build_android:
  image: cirrusci/flutter:3.32.2
  script:
    - flutter pub get
    - flutter build apk --release
  artifacts:
    paths:
      - build/app/outputs/flutter-apk/app-release.apk
    expire_in: 1 week
```

## 推荐方案对比

| 服务 | 免费额度 | 易用性 | 推荐度 |
|------|----------|--------|--------|
| GitHub Actions | 公开仓库无限，私有仓库2000分钟/月 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Codemagic | 500分钟/月 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Bitrise | 200分钟/月 | ⭐⭐⭐ | ⭐⭐⭐ |
| GitLab CI | 400分钟/月 | ⭐⭐⭐ | ⭐⭐⭐ |

## 使用建议

1. **首次使用**：推荐GitHub Actions，配置简单，免费额度充足
2. **团队项目**：考虑Codemagic，提供更多团队协作功能
3. **私有项目**：GitHub Actions私有仓库也有不错的免费额度

## 注意事项

- 确保代码中没有敏感信息（如API密钥）
- 构建时间通常在5-15分钟之间
- 下载的APK文件可以直接安装到Android设备上
- 建议在多个设备上测试APK的兼容性 