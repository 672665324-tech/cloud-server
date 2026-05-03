# ISLA LABS

AI 生成的 Web 作品集，完全由 Claude Code CLI 编写。

## 项目列表

| 项目 | 说明 | 技术 |
|------|------|------|
| [聊天室](chat/) | 实时多人聊天 | Socket.IO |
| [俄罗斯方块对战](tetris/) | 1v1 实时对战 | Socket.IO、SRS |
| [共享白板](whiteboard/) | 协作绘图 | Canvas、Socket.IO |
| [多人贪吃蛇](snake/) | 服务端权威 | Socket.IO、碰撞检测 |
| [服务状态面板](status/) | CPU/内存监控 | Node.js、os module |
| [音乐播放器](music/) | 本地播放、可视化 | Web Audio API、IndexedDB |

## 技术栈

- 前端：原生 HTML/CSS/JS
- 后端：Node.js + Express + Socket.IO
- 数据库：SQLite (better-sqlite3)
- 全部代码由 AI 生成

## 快速开始

```bash
cd web-projects/chat-room
npm install
npm start
```

## 环境变量

复制 `.env.example` 为 `.env`，填入 Cloudflare Tunnel Token：

```bash
cp .env.example .env
# 编辑 .env 填入 CLOUDFLARED_TOKEN
```

## 数据说明

- 账号数据：持久化到 SQLite (`data/app.db`)
- 聊天记录：内存存储，重启丢失
- 白板笔画：内存存储，重启丢失
- 游戏状态：内存存储，重启丢失

## 开始时间

2026.04.29
