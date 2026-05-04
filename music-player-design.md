# #17 音乐播放器 — 二级技术架构

> 介于功能清单和代码之间的实现蓝图
> 文件: `public/music/index.html` (单文件，~1000行)

---

## 一、模块划分

```
index.html
├── 1. DB 层        — IndexedDB 封装 (songs / playlists / stats)
├── 2. Sync 层      — 客户端 ↔ 服务端同步
├── 3. Audio 引擎   — HTMLAudioElement + Web Audio API
├── 4. Meta 解析    — music-metadata-browser 提取 ID3/Vorbis
├── 5. 播放列表管理  — CRUD、排序、队列
├── 6. UI 渲染      — 各面板 DOM 更新
├── 7. 账号桥接     — 游客/注册用户数据策略
└── 8. 入口胶水     — 初始化、事件绑定
```

---

## 二、各模块详细设计

### 模块 1: DB 层 (`DB`)

```js
const DB = {
  _db: null,  // IndexedDB 实例

  // 初始化，建表
  init() → Promise<void>

  // ===== songs 表 =====
  // key: songId (nanoid)
  // value: { id, file: Blob, title, artist, album, duration, cover: Blob|null, fileHash, createdAt }
  addSong(file, meta) → songId
  getSong(id) → songObj
  getAllSongs() → songObj[]
  deleteSong(id) → void
  updateSong(id, fields) → void

  // ===== playlists 表 =====
  // key: playlistId
  // value: { id, name, songIds: string[], createdAt, updatedAt }
  createPlaylist(name) → playlistId
  getPlaylist(id) → playlistObj
  getAllPlaylists() → playlistObj[]
  renamePlaylist(id, name) → void
  deletePlaylist(id) → void
  addToPlaylist(playlistId, songId) → void
  removeFromPlaylist(playlistId, songId) → void
  reorderPlaylist(playlistId, songIds) → void

  // ===== stats 表 =====
  // key: songId
  // value: { songId, playCount, lastPlayed, liked }
  recordPlay(songId) → void
  toggleLike(songId) → void
  getStats(songId) → statsObj
  getAllStats() → statsObj[]
}
```

**IndexedDB schema:**

```
store: songs
  keyPath: id
  index: artist, album, fileHash

store: playlists
  keyPath: id

store: stats
  keyPath: songId
  index: playCount, lastPlayed, liked
```

### 模块 2: Sync 层 (`Sync`)

```
游客模式:
  读写全部走 IndexedDB
  不调任何服务端 API

注册用户模式:
  写入时: IndexedDB 写完 → 异步 POST /api/music/sync
  初始化时: GET /api/music/data → 合并到 IndexedDB
  冲突策略: 服务端 last-write-wins，客户端 IndexedDB 为真相源
```

**服务端 API 设计:**

```
GET  /api/music/data?token=xxx
  → 返回 { songs: [...元数据], playlists: [...], stats: [...] }
  → 不返回文件 Blob（文件只在客户端）

POST /api/music/sync
  body: { token, songs: [...], playlists: [...], stats: [...] }
  → 服务端全量替换该用户的数据
```

**数据迁移（游客→注册）:**

```
用户点注册
  → 前端调 /api/register
  → 拿到新 token
  → 读取 IndexedDB 全部数据
  → POST /api/music/sync 一次性推送到服务端
  → 后续走注册用户同步流程
```

### 模块 3: Audio 引擎 (`AudioEngine`)

```
状态:
  audio: HTMLAudioElement
  ctx: AudioContext (懒加载，首次播放时创建)
  source: MediaElementSourceNode
  analyser: AnalyserNode
  gain: GainNode (音量控制)

方法:
  load(songId) → 从 IndexedDB 读 Blob → createObjectURL → audio.src
  play() / pause() / toggle()
  seek(percent) → audio.currentTime = percent * duration
  setVolume(0-1)
  setPlaybackRate(0.5-2.0)
  getFrequencyData() → Uint8Array (给可视化用)
  getCurrentTime() / getDuration()

事件:
  audio.onended → 触发播放模式决定下一首
  audio.ontimeupdate → 更新进度条
  audio.onloadedmetadata → 更新时长显示

播放模式逻辑:
  MODE_ORDER:  currentIndex++ (到头停止)
  MODE_LOOP_ALL: currentIndex++ (到头回到0)
  MODE_LOOP_ONE: audio.currentTime = 0; play()
  MODE_SHUFFLE: 随机选一个 ≠ currentIndex
```

### 模块 4: Meta 解析 (`MetaParser`)

```
依赖: music-metadata-browser (CDN 引入)

parse(file: File) → Promise<{
  title: string,      // 文件名去后缀作 fallback
  artist: string,     // '未知艺术家' 作 fallback
  album: string,
  duration: number,   // 秒
  cover: Blob|null,   // 从 APIC 帧提取
  fileHash: string    // 前 1MB 的 MD5/SHA-1（用于跨设备匹配）
}>

实现:
  1. const mm = await import('music-metadata-browser')
  2. const metadata = await mm.parseBlob(file)
  3. 提取 common.title / common.artist / common.album / format.duration
  4. 提取 common.picture[0] → Blob
  5. 计算 fileHash (SubtleCrypto.digest SHA-256 取前16字节hex)
  6. fallback: 无标题用文件名，无艺术家用 '未知艺术家'
```

### 模块 5: 播放列表管理 (`PlaylistManager`)

```
内置列表:
  "全部歌曲" — 虚拟列表，= DB.getAllSongs()
  "我喜欢"   — 虚拟列表，= stats.liked === 1 的歌曲
  用户自定义列表 — DB.playlists 表

状态:
  currentPlaylistId: string|null  // 当前激活的列表
  currentSongIndex: number        // 当前播放在列表中的索引
  queue: songId[]                 // 临时队列（优先级高于列表）
  mode: 'order'|'loop_all'|'loop_one'|'shuffle'

方法:
  getCurrentList() → songId[]   // queue 非空用 queue，否则用当前列表
  next() → songId               // 根据 mode 决定
  prev() → songId
  addToQueue(songId) → void     // "下一首播放"
  clearQueue() → void
  createPlaylist(name) → id
  deletePlaylist(id) → void
  renamePlaylist(id, name) → void
  addToPlaylist(playlistId, songId) → void
  removeFromPlaylist(playlistId, songId) → void
```

### 模块 6: UI 渲染 (`UI`)

```
区域划分:
  #sidebar     — 左侧播放列表
  #main        — 右侧歌曲列表 + 搜索 + 上传区
  #player-bar  — 底部播放条
  #visualizer  — 可视化 Canvas（播放条上方，可折叠）

方法:
  renderSidebar()         — 播放列表项 + "全部歌曲" + "我喜欢"
  renderSongList(songs)   — 歌曲表格行
  renderPlayerBar()       — 当前歌曲信息 + 进度 + 控制按钮
  renderPlaylistDetail(id)— 选中列表后右侧显示其歌曲
  updateProgress(current, duration) — 实时更新进度条
  updateVisualizer(freqData) — Canvas 绘制频谱

事件委托:
  #main 上统一 click 代理:
    .song-row → play(songId)
    .song-like → toggleLike(songId)
    .song-delete → removeFromPlaylist(songId)
    .song-queue → addToQueue(songId)

  #sidebar 上统一 click 代理:
    .playlist-item → renderPlaylistDetail(id)
    .playlist-delete → deletePlaylist(id)
    #btn-new-playlist → createPlaylist()

  拖拽上传:
    #drop-zone dragover/dragenter → 高亮
    #drop-zone drop → 读取文件 → processFiles(files)

  搜索:
    #search-input input → 过滤当前列表 → renderSongList(filtered)
```

### 模块 7: 账号桥接 (`AccountBridge`)

```
初始化时:
  读 localStorage.getItem('token')
  调 /api/me 判断 is_guest

游客策略:
  全部读写走 IndexedDB
  #sync-status 显示 "游客模式 · 数据仅存本机"
  注册按钮常驻可见

注册用户策略:
  初始化: GET /api/music/data → 与 IndexedDB 合并
  每次写操作后: debounce 2s → POST /api/music/sync
  #sync-status 显示 "已同步" / "同步中..."

数据迁移:
  doRegister() 成功后:
    1. DB.getAllSongs() + DB.getAllPlaylists() + DB.getAllStats()
    2. POST /api/music/sync
    3. UI 更新同步状态
```

### 模块 8: 入口胶水 (`init`)

```
async function init() {
  await DB.init()
  await AccountBridge.init()
  const songs = await DB.getAllSongs()
  const playlists = await DB.getAllPlaylists()
  UI.renderSidebar(playlists)
  UI.renderSongList(songs)
  绑定拖拽上传
  绑定键盘快捷键
  绑定播放条事件
}
```

---

## 三、数据流

```
上传文件
  → MetaParser.parse(file)
  → DB.addSong(file, meta)
  → AccountBridge.sync() [注册用户]
  → UI.renderSongList()

点击播放
  → PlaylistManager 设 currentIndex
  → AudioEngine.load(songId)
  → AudioEngine.play()
  → DB.recordPlay(songId)
  → UI.renderPlayerBar()
  → Visualizer.start()

歌曲结束
  → AudioEngine.onended
  → PlaylistManager.next() [按 mode 决定]
  → AudioEngine.load(nextId)
  → AudioEngine.play()

搜索
  → input 事件
  → 从当前列表 filter
  → UI.renderSongList(filtered)

跨设备同步（注册用户）
  → 页面加载
  → GET /api/music/data
  → 与 IndexedDB 合并（以服务端为准更新元数据，以本地为准保留 Blob）
  → UI 刷新
```

---

## 四、CSS 变量（和其他项目统一风格）

```css
:root {
  --bg: #0e1a2b;
  --bg-card: rgba(14, 28, 48, 0.7);
  --bg-bar: rgba(10, 20, 38, 0.95);
  --border: rgba(120, 180, 230, 0.15);
  --accent: #7cb8e8;
  --text: #d8e4f0;
  --text-dim: #8aa8c8;
  --green: #4ecca3;
  --red: #e94560;
}
```

---

## 五、外部依赖

```html
<!-- music-metadata-browser，CDN 引入 -->
<script src="https://cdn.jsdelivr.net/npm/music-metadata-browser/dist/music-metadata-browser.min.js"></script>
```

---

## 六、实现顺序（编码步骤）

| 步 | 内容 | 预估行数 |
|----|------|---------|
| 1 | HTML 骨架 + CSS 样式 | ~200 |
| 2 | DB 层 (IndexedDB 封装) | ~80 |
| 3 | 文件上传 + MetaParser | ~60 |
| 4 | AudioEngine + 播放控制栏 | ~120 |
| 5 | 歌曲列表 + 搜索 + 播放模式 | ~80 |
| 6 | 播放列表 CRUD + 拖拽排序 | ~80 |
| 7 | AccountBridge (账号同步) | ~80 |
| 8 | 可视化 (AnalyserNode + Canvas) | ~60 |
| 9 | 歌词解析 + 同步滚动 | ~60 |
| 10 | 播放队列 + 键盘快捷键 | ~40 |
| **合计** | | **~860** |
