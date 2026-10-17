#!/usr/bin/env bash
# =============================================================================
# curl — annotated command examples
# Tier: 3 (Advanced)
# Reference file: read it or copy individual lines. Do not run it as a whole.
# =============================================================================

# ---------------------------------------------------------------------------
### curl — HTTP client and data transfer
# ---------------------------------------------------------------------------
curl http://example.com                     # GET request
curl -o output.html http://example.com      # Save to file
curl -O http://example.com/file.tar.gz      # Save with remote filename
curl -L http://example.com                  # Follow redirects
curl -I http://example.com                  # Headers only (HEAD request)
curl -i http://example.com                  # Headers + body
curl -v http://example.com                  # Verbose (shows TLS, headers, etc.)
curl -s http://example.com                  # Silent (no progress/errors)
curl -S http://example.com                  # Show errors even with -s
curl -f http://example.com                  # Fail silently on HTTP error (exit 22)
curl -# http://example.com                  # Progress bar instead of stats
curl --max-time 30 http://example.com       # Total timeout 30 seconds
curl --connect-timeout 10 http://example.com  # Connection timeout only
curl --retry 3 --retry-delay 5 http://example.com  # Retry failed requests
curl -X POST http://api.example.com/data    # POST request
curl -X PUT http://api.example.com/item/1   # PUT request
curl -X DELETE http://api.example.com/item/1  # DELETE request
curl -d '{"key":"value"}' -H "Content-Type: application/json" http://api.example.com
curl -F "file=@upload.txt" http://example.com/upload   # Upload file (multipart)
curl -F "image=@photo.jpg;type=image/jpeg" http://api.example.com/images
curl -u user:password http://example.com    # Basic authentication
curl -H "Authorization: Bearer TOKEN" http://api.example.com
curl -H "X-Custom-Header: value" http://example.com    # Custom header
curl -k https://self-signed.example.com     # Skip TLS verification (INSECURE)
curl --cacert /etc/ssl/certs/ca-bundle.crt https://example.com  # Custom CA
curl -c cookies.txt http://example.com      # Save cookies
curl -b cookies.txt http://example.com      # Send cookies from file
curl -b "session=abc123" http://example.com # Send inline cookie
# Show only status code and response time
curl -w "%{http_code} %{time_total}s\n" -o /dev/null -s http://example.com
# Multiple metrics
curl -w "Code: %{http_code}\nTime: %{time_total}s\nSize: %{size_download} bytes\n" \
  -o /dev/null -s http://example.com
# Download with rate limit
curl --limit-rate 1M -O http://example.com/bigfile.iso
# Resume download
curl -C - -O http://example.com/bigfile.iso
# Multiple URLs
curl http://example.com/{file1,file2,file3}.txt
curl http://example.com/item[1-100].html    # Range of URLs
# DNS over HTTPS
curl --doh-url https://cloudflare-dns.com/dns-query https://example.com
# View effective URL after redirects
curl -Ls -o /dev/null -w "%{url_effective}" http://short.url/xyz
