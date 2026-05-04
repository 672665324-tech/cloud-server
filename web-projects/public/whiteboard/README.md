# 共享白板 — 项目档案

> URL: https://isla9999.com/whiteboard
> 文件: public/whiteboard/index.html（前端单文件 ~480 行）+ server.js namespace `/whiteboard`

## 技术架构
- 坐标系: 0-1 相对坐标（设备无关，窗口缩放自动适配）
- 渲染: 双缓冲 — offscreen cacheCanvas 缓存笔画，主循环画 cache + 远程光标
- 笔画数据: `{sid, color, size, points: [{x,y}], eraser}`
- 光标同步: `volatile emit`（低延迟，丢包可接受）
- 存储: 服务端最近 500 条笔画，新用户加入时推送 history

## 已知问题
（无遗留问题）

## Bug 修复记录

### 2026-05-01 | Claude (会话 #1)
**问题**: 断线期间正在画的笔画，重连后画布状态不一致
**原因**: 断线时 `drawing=true`、`currentStroke` 指向本地笔画。重连后服务端推送 `history`（清空重建），但客户端 `drawing` 状态和 `currentStroke` 未重置。后续 `pointermove` 操作已不存在的笔画
**修复**: `connect` handler 中重置 `drawing=false`、`currentStroke=null`
**教训**: 重连时不仅要恢复数据状态，还要重置所有交互状态（drawing、dragging 等）

### 2026-05-01 | Claude (会话 #1)
**问题**: offline bar 与 Socket.IO 状态不同步
**修复**: 同聊天室方案
**教训**: 同上

## 技术笔记
- 橡皮擦用 `globalCompositeOperation = 'destination-out'`，不需要真的擦除像素
- `setPointerCapture` 确保拖出画布外仍能收到 pointer 事件
- `canvas.getBoundingClientRect()` 获取画布位置，配合 0-1 坐标计算实际像素
- 重绘性能：500 条笔画时 cacheCanvas 比每帧全量重绘快 10 倍以上
- 账号系统: 连接时 `{ auth: { token } }` 传给中间件，`socket.userName` 自动填充默认昵称
