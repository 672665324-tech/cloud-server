# 服务状态面板 — 项目档案

> URL: https://isla9999.com/status
> 文件: public/status/index.html（前端单文件）+ server.js `/api/status`

## 技术架构
- 数据源: HTTP 轮询 `/api/status`（每 3 秒）
- 服务端: Node.js `os` 模块采集 CPU/内存/运行时间
- CPU 采样: 每 2 秒 diff `os.cpus()` 的 times 计算使用率
- 前端: 原生 DOM 操作 + CSS 动画

## 已知问题
（无遗留问题）

## Bug 修复记录
（暂无）

## 技术笔记
- CPU 使用率计算：`1 - idleDiff / totalDiff`，两次采样差值
- Sparkline 用 CSS 渐变 + 定位实现，不用 Canvas
- 每个服务的状态卡片独立渲染，互不影响
- 30 个采样点的历史曲线（约 90 秒数据）
