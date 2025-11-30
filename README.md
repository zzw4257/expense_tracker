# Expense Tracker 报销管理系统

跨平台报销管理应用，支持 Web、Android、iOS。

## 功能

- **报销记录管理** - 创建、编辑、删除报销记录
- **凭证管理** - 发票上传、税号验证（统一社会信用代码）
- **数据分析** - 类别分布、月度趋势图表
- **数据导出** - CSV/JSON格式导出
- **响应式设计** - 适配桌面和移动端

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter 3.x |
| 状态管理 | Provider |
| 后端 | Vercel Serverless |
| 部署 | Vercel + GitHub |

## 本地开发

```bash
# 安装依赖
flutter pub get

# 运行Web版
flutter run -d chrome

# 运行Android
flutter run -d android

# 运行iOS
flutter run -d ios
```

## 构建

```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 部署到Vercel

1. Fork本仓库到GitHub
2. 在Vercel中导入项目
3. 配置构建命令: `flutter build web --release`
4. 输出目录: `build/web`
5. 部署

## 项目结构

```
lib/
├── main.dart           # 应用入口
├── models/             # 数据模型
├── providers/          # 状态管理
├── screens/            # 页面
├── theme/              # 主题配置
└── widgets/            # 可复用组件

api/
├── expenses.js         # 报销API
└── validate-tax.js     # 税号验证API
```

## UI风格

Neon渐变 + 深色背景 + 像素字体，街机风格微交互。
