`curl` is extremely versatile—used for HTTP requests, APIs, downloads, uploads, debugging, automation, and more. Instead of dumping hundreds of flags blindly, here’s a **well-organized, practical guide** covering _all major categories of curl commands_, with real examples you can actually use.

---

# 🌐 1. Basic Requests

### GET (default)

```bash
curl https://api.example.com
```

### Save response to file

```bash
curl -o output.json https://api.example.com
```

### Silent mode

```bash
curl -s https://api.example.com
```

---

# 📡 2. HTTP Methods

### POST

```bash
curl -X POST https://api.example.com
```

### PUT

```bash
curl -X PUT https://api.example.com/resource/1
```

### DELETE

```bash
curl -X DELETE https://api.example.com/resource/1
```

### PATCH

```bash
curl -X PATCH https://api.example.com/resource/1
```

---

# 📦 3. Sending Data

### Form data

```bash
curl -X POST -d "name=Sankar&age=25" https://api.example.com
```

### JSON data

```bash
curl -X POST https://api.example.com \
  -H "Content-Type: application/json" \
  -d '{"name":"Sankar","role":"dev"}'
```

### From file

```bash
curl -X POST -d @data.json https://api.example.com
```

---

# 🔐 4. Authentication

### Basic auth

```bash
curl -u username:password https://api.example.com
```

### Bearer token

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" https://api.example.com
```

### API key header

```bash
curl -H "x-api-key: YOUR_KEY" https://api.example.com
```

---

# 📁 5. File Uploads & Downloads

### Download file

```bash
curl -O https://example.com/file.zip
```

### Resume download

```bash
curl -C - -O https://example.com/file.zip
```

### Upload file

```bash
curl -F "file=@myfile.txt" https://api.example.com/upload
```

---

# 🍪 6. Cookies & Sessions

### Save cookies

```bash
curl -c cookies.txt https://example.com
```

### Send cookies

```bash
curl -b cookies.txt https://example.com
```

---

# 🔍 7. Headers & Debugging

### Show response headers

```bash
curl -i https://example.com
```

### Only headers

```bash
curl -I https://example.com
```

### Verbose (debug mode)

```bash
curl -v https://example.com
```

### Custom headers

```bash
curl -H "User-Agent: MyApp" https://example.com
```

---

# 🔁 8. Redirects

### Follow redirects

```bash
curl -L https://example.com
```

---

# ⚡ 9. Performance & Limits

### Limit rate

```bash
curl --limit-rate 100k https://example.com/file
```

### Timeout

```bash
curl --max-time 5 https://example.com
```

---

# 🌍 10. Proxies

```bash
curl -x http://proxy:8080 https://example.com
```

With auth:

```bash
curl -x http://user:pass@proxy:8080 https://example.com
```

---

# 🔗 11. Query Parameters

```bash
curl "https://api.example.com/search?q=curl&page=1"
```

With encoding:

```bash
curl --data-urlencode "q=curl commands" https://api.example.com/search
```

---

# 📊 12. Output Formatting

### Write response + status

```bash
curl -w "\nStatus: %{http_code}\n" https://example.com
```

### Save headers separately

```bash
curl -D headers.txt https://example.com
```

---

# 🔄 13. Multiple Requests

```bash
curl https://api1.com https://api2.com
```

---

# 🔒 14. SSL / HTTPS

### Ignore SSL errors

```bash
curl -k https://example.com
```

### Use certificate

```bash
curl --cert cert.pem https://example.com
```

---

# 📡 15. FTP / SCP / SFTP

### FTP download

```bash
curl ftp://example.com/file.txt -u user:pass
```

### SFTP upload

```bash
curl -T file.txt sftp://example.com/ --user user
```

---

# 🧪 16. Advanced Tricks

### Retry on failure

```bash
curl --retry 5 https://example.com
```

### Parallel downloads

```bash
curl -Z -O https://site.com/file1 -O https://site.com/file2
```

### IPv4 only

```bash
curl -4 https://example.com
```

### IPv6 only

```bash
curl -6 https://example.com
```

---

# 🧠 17. Real-World API Example

```bash
curl -X POST https://api.github.com/user/repos \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-repo"}'
```

---

# ⚙️ 18. Useful Flags Cheat Sheet

| Flag | Meaning             |
| ---- | ------------------- |
| `-X` | HTTP method         |
| `-d` | Send data           |
| `-H` | Header              |
| `-o` | Output file         |
| `-O` | Save with same name |
| `-u` | Auth                |
| `-v` | Verbose             |
| `-I` | Headers only        |
| `-L` | Follow redirects    |
| `-F` | Form upload         |
| `-k` | Ignore SSL          |
| `-s` | Silent              |

---

# 🚀 If you want to go deeper

I can give you:

- 🔥 curl for **REST API testing like Postman**
- 🧠 curl for **shell scripting automation**
- ⚔️ curl tricks used in **bug bounty / security testing**
- 🐳 curl inside **Docker / CI pipelines**

Just tell me what direction you want.

---

## Files

- [examples.sh](examples.sh)
