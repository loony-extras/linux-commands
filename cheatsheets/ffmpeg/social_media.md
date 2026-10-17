Got it — the issue was the code blocks inside tables (Markdown doesn’t handle those well). Here’s a **properly formatted version** with clean tables + separate code blocks.

---

# 🎬 YouTube Upload Recipes

### 📊 Overview

| Goal           | Notes                        |
| -------------- | ---------------------------- |
| Standard 1080p | Best quality + compatibility |
| 60 FPS         | Smooth playback              |
| 4K             | UHD upload                   |

---

### ✅ Standard YouTube (1080p)

```bash
ffmpeg -i input.mp4 -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart output.mp4
```

---

### ✅ Force 60 FPS

```bash
ffmpeg -i input.mp4 -r 60 -c:v libx264 -crf 20 -preset slow -c:a aac -b:a 192k output.mp4
```

---

### ✅ 4K Upload

```bash
ffmpeg -i input.mp4 -vf scale=3840:2160 -c:v libx264 -crf 18 -preset slow -c:a aac -b:a 256k output_4k.mp4
```

---

# 📱 Reels / Shorts (Vertical Video)

### 📊 Overview

| Goal    | Notes                 |
| ------- | --------------------- |
| Resize  | Quick but may stretch |
| Crop    | Better framing        |
| Blur BG | Professional look     |
| Trim    | Keep under 60s        |

---

### ✅ Resize to Vertical (9:16)

```bash
ffmpeg -i input.mp4 -vf "scale=1080:1920,setsar=1" -c:v libx264 -crf 20 -preset fast -c:a aac -b:a 128k reel.mp4
```

---

### ✅ Crop Center for Vertical

```bash
ffmpeg -i input.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" -c:v libx264 -crf 20 -preset fast reel.mp4
```

---

### ✅ Blur Background (Pro Style)

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]scale=1080:1920,boxblur=20[bg];[0:v]scale=1080:-1[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2" -c:v libx264 -crf 22 reel.mp4
```

---

### ✅ Trim to 60 seconds

```bash
ffmpeg -i input.mp4 -t 60 -c copy short.mp4
```

---

# 🗜️ Compression Presets

### 📊 Overview

| Level        | CRF | Notes              |
| ------------ | --- | ------------------ |
| High quality | 18  | Near lossless      |
| Balanced     | 23  | Default sweet spot |
| Small size   | 28  | Good compression   |
| Very small   | 32  | Quality drops      |

---

### ✅ High Quality

```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 18 -preset slow output.mp4
```

---

### ✅ Balanced (Recommended)

```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium output.mp4
```

---

### ✅ Smaller Size

```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 28 -preset slow output.mp4
```

---

### ✅ Very Small File

```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 32 -preset slow output.mp4
```

---

# ⚡ Speed & Optimization

### 📊 Overview

| Goal         | Notes        |
| ------------ | ------------ |
| Fast encode  | Less CPU     |
| GPU encode   | Use hardware |
| No re-encode | Instant      |

---

### ✅ Fast Encoding

```bash
ffmpeg -i input.mp4 -c:v libx264 -preset ultrafast -crf 28 output.mp4
```

---

### ✅ GPU (NVIDIA)

```bash
ffmpeg -i input.mp4 -c:v h264_nvenc -preset fast output.mp4
```

---

### ✅ Copy Without Re-encoding

```bash
ffmpeg -i input.mp4 -c copy output.mp4
```

---

# 🎧 Audio Recipes

### 📊 Overview

| Goal          | Notes        |
| ------------- | ------------ |
| Extract audio | High quality |
| Normalize     | Fix volume   |

---

### ✅ Extract Audio (MP3 320kbps)

```bash
ffmpeg -i input.mp4 -vn -c:a mp3 -b:a 320k audio.mp3
```

---

### ✅ Normalize Audio

```bash
ffmpeg -i input.mp4 -af "loudnorm" output.mp4
```

---

# 📱 Social Media Presets

### 📊 Overview

| Platform  | Format     |
| --------- | ---------- |
| Instagram | Square     |
| WhatsApp  | Compressed |
| Twitter/X | Balanced   |

---

### ✅ Instagram (Square)

```bash
ffmpeg -i input.mp4 -vf scale=1080:1080 -c:v libx264 -crf 23 insta.mp4
```

---

### ✅ WhatsApp Optimized

```bash
ffmpeg -i input.mp4 -vf scale=640:-1 -c:v libx264 -crf 28 -preset fast wa.mp4
```

---

### ✅ Twitter/X Upload

```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 22 -preset fast -c:a aac -b:a 128k twitter.mp4
```

---

# 🔥 Pro Tips

| Tip             | Why it matters     |
| --------------- | ------------------ |
| `CRF 18–23`     | Best quality range |
| `preset slow`   | Better compression |
| `+faststart`    | Faster streaming   |
| `-c copy`       | No quality loss    |
| Combine filters | Powerful editing   |

---

If you want, I can make this even better with:

- 📦 **copy-paste script to process entire folders**
- 🎬 **cinematic presets (Netflix-style look)**
- ⚡ **ultra compression for low bandwidth**
