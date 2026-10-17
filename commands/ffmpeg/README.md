Here’s a **clean, practical table cheat sheet** for `ffmpeg`—focused on real-world usage (very useful for devs, content, automation):

---

# 📊 `ffmpeg` Command – Complete Table

| Category                     | Command / Option         | What it Does                    | Example                                                  |
| ---------------------------- | ------------------------ | ------------------------------- | -------------------------------------------------------- |
| **Basic**                    | `ffmpeg -i input output` | Convert media format            | `ffmpeg -i video.mp4 video.avi`                          |
|                              | `-y`                     | Overwrite output without asking | `ffmpeg -y -i in.mp4 out.mp4`                            |
| **Video Conversion**         | `-c:v libx264`           | Encode video (H.264)            | `ffmpeg -i in.mkv -c:v libx264 out.mp4`                  |
|                              | `-crf n`                 | Quality (lower = better)        | `-crf 23`                                                |
|                              | `-preset`                | Speed vs compression            | `-preset fast`                                           |
| **Audio Conversion**         | `-c:a aac`               | Convert audio codec             | `ffmpeg -i in.mp4 -c:a aac out.mp4`                      |
|                              | `-b:a`                   | Audio bitrate                   | `-b:a 192k`                                              |
| **Extract Audio**            | `-vn`                    | Remove video, keep audio        | `ffmpeg -i video.mp4 -vn audio.mp3`                      |
| **Extract Video**            | `-an`                    | Remove audio                    | `ffmpeg -i video.mp4 -an out.mp4`                        |
| **Trim Video**               | `-ss`                    | Start time                      | `ffmpeg -ss 00:00:10 -i in.mp4 out.mp4`                  |
|                              | `-t`                     | Duration                        | `ffmpeg -i in.mp4 -t 30 out.mp4`                         |
| **Resize Video**             | `-vf scale=WxH`          | Resize resolution               | `ffmpeg -i in.mp4 -vf scale=1280:720 out.mp4`            |
| **Change FPS**               | `-r`                     | Set frame rate                  | `ffmpeg -i in.mp4 -r 30 out.mp4`                         |
| **Compress Video**           | `-crf + preset`          | Reduce size efficiently         | `ffmpeg -i in.mp4 -crf 28 -preset slow out.mp4`          |
| **Add Subtitles**            | `-vf subtitles=file.srt` | Burn subtitles                  | `ffmpeg -i in.mp4 -vf subtitles=sub.srt out.mp4`         |
| **Remove Subtitles**         | `-sn`                    | Disable subtitles               | `ffmpeg -i in.mkv -sn out.mp4`                           |
| **Merge Audio & Video**      | `-c copy`                | Combine streams                 | `ffmpeg -i video.mp4 -i audio.mp3 -c copy out.mp4`       |
| **Extract Frames**           | `-vf fps=1`              | Save frames as images           | `ffmpeg -i in.mp4 -vf fps=1 img_%03d.png`                |
| **Create Video from Images** | `-framerate`             | Make video from images          | `ffmpeg -framerate 24 -i img_%03d.png out.mp4`           |
| **GIF Creation**             | `-vf fps,scale`          | Convert video to GIF            | `ffmpeg -i in.mp4 -vf "fps=10,scale=320:-1" out.gif`     |
| **Rotate Video**             | `-vf transpose`          | Rotate video                    | `ffmpeg -i in.mp4 -vf transpose=1 out.mp4`               |
| **Crop Video**               | `-vf crop`               | Crop frame                      | `ffmpeg -i in.mp4 -vf crop=640:480:0:0 out.mp4`          |
| **Speed Up / Slow Down**     | `-filter:v setpts`       | Change speed                    | `setpts=0.5*PTS` (2x speed)                              |
| **Change Audio Speed**       | `-filter:a atempo`       | Adjust audio speed              | `atempo=2.0`                                             |
| **Watermark**                | `-vf overlay`            | Add logo/image                  | `ffmpeg -i in.mp4 -i logo.png -vf overlay=10:10 out.mp4` |
| **Screen Recording**         | `-f x11grab`             | Record screen (Linux)           | `ffmpeg -f x11grab -i :0.0 out.mkv`                      |
| **Webcam Recording**         | `-f v4l2`                | Capture webcam                  | `ffmpeg -f v4l2 -i /dev/video0 out.mp4`                  |
| **Streaming**                | `-f flv`                 | Stream to server                | `ffmpeg -re -i in.mp4 -f flv rtmp://...`                 |
| **Metadata**                 | `-metadata`              | Add metadata                    | `-metadata title="My Video"`                             |
| **Show Info**                | `-i`                     | Show file info                  | `ffmpeg -i video.mp4`                                    |

---

# ⚡ Most Useful (Real-World Picks)

| Trick                                                | Why it matters           |
| ---------------------------------------------------- | ------------------------ |
| `ffmpeg -i in.mp4 -crf 28 -preset slow out.mp4`      | Best compression balance |
| `ffmpeg -i video.mp4 -vn audio.mp3`                  | Extract audio quickly    |
| `ffmpeg -ss 00:01:00 -t 10 -i in.mp4 out.mp4`        | Clip video fast          |
| `ffmpeg -i in.mp4 -vf scale=1280:720`                | Resize for web           |
| `ffmpeg -i in.mp4 -vf "fps=10,scale=320:-1" out.gif` | Create GIFs              |
| `ffmpeg -i in.mp4 -vf subtitles=sub.srt`             | Burn subtitles           |
| `ffmpeg -i in.mp4 -an out.mp4`                       | Remove audio             |
| `ffmpeg -i in.mp4 -vf crop=...`                      | Fix framing issues       |

---

If you want, I can go next level with:

- 🎬 **ready-made ffmpeg recipes (YouTube, reels, compression presets)**
- ⚡ **real dev workflows (automation, batch scripts, pipelines)**

---

## Files

- [dev_usecases.md](dev_usecases.md)
- [social_media.md](social_media.md)
