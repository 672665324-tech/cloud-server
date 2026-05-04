# Cloud Server

AI 生成的 Web 作品集，Express + Socket.IO，通过 Cloudflare Tunnel 暴露到 `isla9999.com`。

## 功能

所有功能集成在 [`web-projects/chat-room/`](web-projects/chat-room/) 中，共享同一后端服务。

| # | 项目 | URL | 说明 |
|---|------|-----|------|
| 1 | 实时聊天室 | `/chat` | 多人在线通讯、在线用户列表 |
| 2 | 俄罗斯方块对战 | `/tetris` | 1v1 实时对战、SRS 旋转系统 |
| 3 | 共享白板 | `/whiteboard` | 协作绘图、volatile 光标 |
| 4 | 多人贪吃蛇 | `/snake` | 服务端权威、碰撞检测 |
| 5 | 服务状态面板 | `/status` | CPU/内存/服务监控 |
| 17 | 音乐播放器 | `/music` | 本地文件播放、频谱可视化、SQLite 同步 |
| 18 | 统一账号系统 | `/api/*` | SQLite、JWT、游客模式 |

## 快速开始

```bash
cd web-projects/chat-room
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
| 音乐数据 | 客户端 IndexedDB + 服务端 SQLite | 保留 |
| 聊天记录 | 内存 | 清空 |
| 白板笔画 | 内存 | 清空 |
| 游戏状态 | 内存 | 清空 |

## 许可

代码由 MiMo v2.5 Pro、DeepSeek V4 Pro 及 Claude Code CLI 生成。
