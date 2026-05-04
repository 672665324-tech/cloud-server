# 音乐播放器 — 项目档案

> URL: https://isla9999.com/music
> 文件: public/music/index.html（前端单文件 ~600 行）+ server.js `/api/music/*` 路由

## 技术架构
- 音频引擎: HTMLAudioElement + Web Audio API (AnalyserNode 可视化)
- 存储: IndexedDB — songs(Blob+元数据) / playlists / stats 三表
- 元数据: music-metadata-browser 解析 ID3/Vorbis 标签
- 歌词: 原生解析 LRC 格式 `[mm:ss.xx]`，逐行高亮同步
- 可视化: Canvas 2D + AnalyserNode.getByteFrequencyData 频谱柱状图
- 布局: 左侧播放列表 + 右侧歌曲列表 + 底部播放条 + 可视化面板

## 账号系统集成
- 游客模式: 数据仅存 IndexedDB，不调服务端同步 API
- 注册用户: 写入 IndexedDB 后 debounce 2s 推送到 SQLite
- 数据迁移: 注册时读取 IndexedDB 全量数据 → POST /api/music/sync
- 服务端只存元数据，不存音频文件（文件太大，留在客户端）

## 服务端 API
- `GET /api/music/data?token=xxx` — 获取用户音乐数据（元数据+播放列表+统计）
- `POST /api/music/sync` — 全量同步（注册用户专用，游客返回 400）

## 数据库表
- `music_songs` — 歌曲元数据 (id, user_id, title, artist, album, duration, file_hash)
- `music_playlists` — 播放列表 (id, user_id, name, sort_order)
- `music_playlist_songs` — 列表-歌曲关联 (playlist_id, song_id, sort_order)
- `music_stats` — 播放统计 (user_id, song_id, play_count, last_played, liked)

## 已知问题
（无遗留问题）

## Bug 修复记录

### 2026-05-01 | Claude (会话 #2)
**问题**: 实现音乐播放器 #17
**原因**: 新功能开发
**修复**: 完整实现 P0+P1 功能，包括本地上传、播放控制、播放列表、可视化、歌词、账号同步
**教训**: IndexedDB 适合存大文件(Blob)，SQLite 适合存元数据和关联关系；同步策略应以客户端 IndexedDB 为真相源，服务端只做备份

## 技术笔记
- `music-metadata-browser` 通过 CDN 引入，解析 Blob 得到 ID3/Vorbis 标签
- 封面图片从 `common.picture[0]` 提取，转为 Blob 存入 IndexedDB
- 文件 hash 用 SubtleCrypto.digest SHA-256 取前 16 字节 hex，用于跨设备匹配
- Web Audio API 需要用户交互后才能创建 AudioContext（autoplay policy）
- `createMediaElementSource` 只能对同一个 audio 元素调用一次
- 歌词解析用正则 `\[(\d+):(\d+\.?\d*)\](.*)` 匹配 LRC 时间标签
- 账号同步用 debounce 2s 避免频繁写入，游客不触发同步
