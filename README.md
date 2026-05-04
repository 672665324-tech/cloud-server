# Cloud Server

AI 生成的 Web 作品集。

## 功能

所有功能集成在 [`web-projects/`](web-projects/) 中，共享同一后端服务。

| 功能 | 说明 |
|------|------|
| 实时聊天 | 多人聊天室，支持表情和消息历史 |
| 俄罗斯方块 | 1v1 实时对战，SRS 旋转系统 |
| 共享白板 | 协作绘图，5 秒清除冷却 |
| 多人贪吃蛇 | 服务端权威，Delta 增量更新减少带宽 |
| 音乐播放器 | 本地文件播放、频谱可视化 |

## 快速开始

```bash
cd web-projects
npm install
node server.js
```

服务默认运行在 `http://localhost:3000`。

## 环境变量（可选）

如需通过 Cloudflare Tunnel 公开部署，复制 `.env.example` 为 `.env` 并填入 Token：

```bash
cp .env.example .env
# 编辑 .env，填入 CLOUDFLARED_TOKEN
```

不配置则仅本地可访问。

## 数据存储

| 数据 | 存储方式 | 重启后 |
|------|----------|--------|
| 账号系统 | SQLite 文件 (`data/app.db`) | 保留 |
| 聊天记录 | 内存 | 清空 |
| 白板笔画 | 内存 | 清空 |
| 游戏状态 | 内存 | 清空 |

## 许可

代码由 MiMo v2.5 Pro、DeepSeek V4 Pro 及 Claude Code CLI 生成。
