# 聊天室 — 项目档案

> URL: https://isla9999.com/chat
> 文件: public/chat/index.html（前端单文件）+ server.js（后端 namespace `/`）

## 技术架构
- 前端: 原生 HTML/CSS/JS，单文件内联
- 后端: Express + Socket.IO，默认 namespace `/`
- 通信: WebSocket（自动降级 polling）
- 存储: 内存（最近 200 条消息，在线用户 Map）

## 已知问题
（无遗留问题）

## Bug 修复记录

### 2026-05-01 | Claude (会话 #1)
**问题**: 断网重连后消息全部重复显示
**原因**: Socket.IO 重连后 `connect` 事件触发 → 重新 `join` → 服务端推送 `history` → 客户端直接追加，不清空旧消息
**修复**: `history` handler 先 `document.getElementById('messages').innerHTML = ''` 再追加
**教训**: 所有"重连后重新获取全量数据"的场景，都要先清空本地旧数据

### 2026-05-01 | Claude (会话 #1)
**问题**: offline bar 与 Socket.IO 断线状态不同步
**原因**: 用 `fetch('/ping')` 轮询控制 offline bar，与 Socket.IO 状态独立，可能同时显示"已连接"和"断线"
**修复**: Socket.IO `connect`/`disconnect` 事件作为主要触发，fetch 仅作网络中断的后备检测
**教训**: 一个实时应用不应该有两套独立的连接状态检测

## 技术笔记
- HTML 转义用 `textContent` → `innerHTML`，不用正则
- `100dvh` 处理移动端浏览器地址栏高度变化
- Socket.IO namespace `/` 是聊天专用，其他服务用 `/tetris` 等
- 账号系统: 连接时 `{ auth: { token } }` 传给中间件，`socket.userName` 自动填充默认昵称
