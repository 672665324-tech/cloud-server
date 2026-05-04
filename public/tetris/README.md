# 俄罗斯方块对战 — 项目档案

> URL: https://isla9999.com/tetris
> 文件: public/tetris/index.html（前端单文件 ~680 行）+ server.js namespace `/tetris`

## 技术架构
- 游戏引擎: 客户端权威，服务端做状态中继 + 攻击验证
- 旋转系统: SRS + kick table（JLSTZ 一套，I 一套）
- 随机器: 7-bag（每 7 块打乱一次）
- 房间系统: 创建/加入/观战，准备 → 倒计时 → 开始
- 心跳: 客户端 1s 发送，服务端 5s 检测，8s 超时断线
- 断线重连: 60 秒窗口，sessionStorage 存房间 ID 和昵称

## 已知问题
（无遗留问题）

## Bug 修复记录

### 2026-05-01 | Claude (会话 #1)
**问题**: 断网重连后游戏画面被大厅覆盖
**原因**: 重连时同时发送 `set-name` 和 `rejoin`。如果 `name-ok` 响应在 `game-resume` 之后到达，`name-ok` 回调会执行 `show('scr-lobby')`，覆盖已恢复的游戏画面
**修复**: ① 重连时不再发 `set-name`；② `name-ok` 回调增加 `rejoining` 守卫标志；③ `rejoining` 在 `game-resume`/`rejoin-failed`/`toMenu` 时重置
**教训**: 多个异步响应竞争同一 UI 时，必须用状态标志控制哪个响应有权修改 UI

### 2026-05-01 | Claude (会话 #1)
**问题**: 观战者在几秒内被自动踢出房间
**原因**: 服务端心跳监控检查所有 players 和 spectators 的 `_hb` 时间戳。但客户端 `startHB()` 只在 `startLoop()` 中调用，而 `startLoop` 只对玩家（myPn!==0）执行。观战者从不发心跳 → `_hb` 未定义 → 被踢
**修复**: `onGameStart` 中观战者（myPn===0）也调用 `startHB()`
**教训**: 心跳机制必须覆盖所有需要保活的角色，不只是主操作者

### 2026-05-01 | Claude (会话 #1)
**问题**: offline bar 与 Socket.IO 状态不同步
**原因**: fetch 轮询和 Socket.IO 各自维护连接状态
**修复**: Socket.IO `connect`/`disconnect` 驱动 offline bar，fetch 仅作后备
**教训**: 同上（聊天室）

### 2026-05-01 | Claude (会话 #2)
**问题**: 接入统一账号系统 (#18)
**原因**: 子项目需要使用账号系统的身份信息
**修复**: ① 客户端连接时传递 `localStorage.getItem('token')` 作为 auth；② 服务端 `set-name` 和 `rejoin` 使用 `socket.userName`（中间件注入）作为默认昵称；③ 客户端监听 `guest-token` 事件保存新 token
**教训**: Socket.IO 中间件可以在握手阶段注入用户信息到 socket 对象，子项目只需在连接时传 token，无需自行实现认证逻辑

## 技术笔记
- `volatile emit` 用于光标同步（丢包可接受），普通 emit 用于游戏状态（必须送达）
- `sessionStorage` 持久化房间 ID，刷新页面可自动重连
- 移动端触控：`touch-action: manipulation` 消除 300ms 延迟
- Canvas 渲染：主棋盘 300×600，对手棋盘 180×360，按比例缩放
- 账号系统: 连接时 `{ auth: { token } }` 传给中间件，`socket.userName` 自动填充
