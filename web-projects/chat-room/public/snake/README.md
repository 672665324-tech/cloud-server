# 多人贪吃蛇 — 项目档案

> URL: https://isla9999.com/snake
> 文件: public/snake/index.html（前端单文件 ~440 行）+ server.js namespace `/snake`

## 技术架构
- 权威模型: **服务端权威** — 所有逻辑（移动、碰撞、食物）在服务端
- 游戏循环: 服务端 `setInterval` 150ms tick
- 渲染: 客户端双帧插值（prevState → currState，150ms 内平滑过渡）
- 碰撞: 碰墙死亡、碰蛇身死亡、同格头部相撞双亡
- 死亡: 3 秒后自动重生，尸体掉落食物

## 已知问题
（无遗留问题）

## Bug 修复记录

### 2026-05-01 | Claude (会话 #1)
**问题**: 断线后蛇直接消失，重连从零开始（分数、长度全丢）
**原因**: 服务端 `disconnect` handler 直接 `snakes.delete(sock.id)`，不保留任何数据。客户端重连后 emit `join`，服务端创建全新蛇
**修复**:
- 服务端: 新增 `snDisconnected` Map，断线时保留蛇数据 30 秒；新增 `rejoin` handler 恢复数据
- 客户端: `reconnect` 事件发送 `rejoin` 而非 `join`；新增 `rejoined` 标志防止 `connect`/`reconnect` 双发
**教训**: 所有需要断线重连的实时应用，断线时应保留状态而非删除。用 name 匹配重连（因为新 socket ID 不同）

### 2026-05-01 | Claude (会话 #1)
**问题**: 重连时 `join` 和 `rejoin` 双发导致重复处理
**原因**: Socket.IO 重连时 `reconnect`（manager 事件）和 `connect`（socket 事件）都会触发，客户端两个 handler 各发一个事件
**修复**: 用 `rejoined` 标志：`reconnect` 时设为 true 并发 `rejoin`；`connect` 时检查标志，true 则跳过 `join` 并重置
**教训**: Socket.IO 重连会触发 `reconnect` + `connect` 两个事件，如果两个都要发消息，必须防重复

### 2026-05-01 | Claude (会话 #1)
**问题**: 服务端 rejoin handler 中 `sn.name = restoredSnake` 把对象赋给了 name
**原因**: 复制粘贴错误，应该是 `restoredSnake.name`
**修复**: 改为 `sn.name = restoredSnake.name`
**教训**: 赋值时检查右值类型，尤其是对象解构/复制场景

### 2026-05-01 | Claude (会话 #2)
**问题**: 接入统一账号系统 (#18)
**修复**: 客户端连接时传递 token，服务端 `join` 使用 `socket.userName` 作为默认昵称

## 技术笔记
- 服务端权威的好处：防作弊，所有客户端看到一致状态
- 账号系统: 连接时 `{ auth: { token } }` 传给中间件，`socket.userName` 自动填充默认昵称
- 双帧插值：`t = elapsed / 150`，`body[i] = prev[i] + (curr[i] - prev[i]) * t`
- 蛇身渐变透明度：`alpha = 1 - i/body.length * 0.5`
- 蛇头眼睛方向：根据 `body[0] - body[1]` 的差值计算朝向
- `roundRect` polyfill 兼容旧浏览器
