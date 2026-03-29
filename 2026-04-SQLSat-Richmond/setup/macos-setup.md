# macOS Setup — SQL Server 2025 + Ollama + nginx TLS Proxy

Translated from Nocentino's Windows/PowerShell setup (Dec 2025).
Some steps may have changed — verify versions before running.

## Prerequisites
- Docker Desktop installed (for SQL Server 2025 container)
- Homebrew installed

## Step 1: SQL Server 2025 (via Docker)
Already handled — see main project file for `docker run` commands.
No native macOS install exists for SQL Server.

## Step 2: SQL Client Tool
SSMS is Windows-only. macOS options:

```bash
# Option A: Azure Data Studio (GUI — cross-platform SSMS alternative)
brew install --cask azure-data-studio

# Option B: sqlcmd CLI (lightweight, good for scripting)
# Included with mssql-tools — install via:
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew update
brew install mssql-tools18
```

## Step 3: Install Ollama, OpenSSL, nginx

```bash
# Ollama — runs natively on ARM64 Mac (no QEMU emulation like SQL Server)
brew install ollama

# OpenSSL — macOS ships LibreSSL, but Homebrew OpenSSL is more compatible
brew install openssl

# nginx — reverse proxy for TLS termination in front of Ollama
brew install nginx
```

### Key macOS paths (vs. Windows)
| Tool | macOS (Homebrew) | Windows (Choco) |
|------|-----------------|-----------------|
| OpenSSL binary | `/opt/homebrew/opt/openssl/bin/openssl` | `C:\Program Files\OpenSSL-Win64\bin\openssl.exe` |
| nginx config | `/opt/homebrew/etc/nginx/nginx.conf` | `C:\nginx\<version>\conf\nginx.conf` |
| nginx service | `brew services start/stop/restart nginx` | `nssm restart nginx` |

## Step 4: Create Config Directory

```bash
mkdir -p ~/sqlsat-demo/config
mkdir -p ~/sqlsat-demo/certs
```

## Step 5: Generate nginx Config

```bash
cat > ~/sqlsat-demo/config/nginx.conf << 'EOF'
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    upstream ollama {
        server 127.0.0.1:11434;
    }

    server {
        listen 443 ssl;
        server_name model.example.com;

        ssl_certificate "/Users/$USER/sqlsat-demo/certs/nginx.crt";
        ssl_certificate_key "/Users/$USER/sqlsat-demo/certs/nginx.key";
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://ollama;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Origin '';
            proxy_set_header Referer '';
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 300;
            send_timeout 300;
        }
    }
}
EOF
```

**NOTE:** The `$USER` in the cert paths needs to be your actual username, and the `$host`, `$remote_addr`, etc. are nginx variables (not shell variables). The heredoc `'EOF'` (quoted) prevents shell expansion — but you'll need to manually replace `$USER` in the cert paths with your actual username (`dpurnell`), OR use an unquoted heredoc and escape the nginx variables. Safest approach: edit the file after creation to set correct cert paths.

### Differences from Windows config:
- Updated `ssl_protocols` to `TLSv1.2 TLSv1.3` (TLSv1 and TLSv1.1 are deprecated — consider updating for the presentation)
- Paths use macOS conventions instead of `C:\`

## Step 6: Generate OpenSSL Config

```bash
cat > ~/sqlsat-demo/config/openssl.cnf << 'EOF'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = NC
L = Burlington
O = IT
OU = DataTeam
CN = my-ai.demo

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = 127.0.0.1
DNS.1 = localhost
EOF
```

## Step 7: Generate Self-Signed Certificate

```bash
# Use Homebrew's OpenSSL (not macOS LibreSSL)
/opt/homebrew/opt/openssl/bin/openssl req -x509 -nodes -days 3650 \
  -newkey rsa:2048 \
  -keyout ~/sqlsat-demo/certs/nginx.key \
  -out ~/sqlsat-demo/certs/nginx.crt \
  -config ~/sqlsat-demo/config/openssl.cnf
```

## Step 8: Trust the Certificate (macOS Keychain)

```bash
# Windows uses X509Store to add to "Root" / "LocalMachine"
# macOS uses the System Keychain
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/sqlsat-demo/certs/nginx.crt
```

## Step 9: Deploy nginx Config & Start

```bash
# Back up default config
cp /opt/homebrew/etc/nginx/nginx.conf /opt/homebrew/etc/nginx/nginx.conf.bak

# Copy custom config
cp ~/sqlsat-demo/config/nginx.conf /opt/homebrew/etc/nginx/nginx.conf

# IMPORTANT: Edit the config to replace $USER with actual username in cert paths
# Or use absolute paths from the start

# Start (or restart) nginx via Homebrew services
brew services restart nginx
```

## Step 10: Pull Ollama Model & Start Service

```bash
# Start Ollama service (listens on http://localhost:11434)
ollama serve &
# Or: brew services start ollama

# Pull the embedding model
ollama pull nomic-embed-text
```

## Step 11: Test the TLS Proxy

```bash
# Test via curl (macOS equivalent of Invoke-WebRequest)
curl -X POST https://localhost/api/embeddings \
  -H "Content-Type: application/json" \
  -d '{"model": "nomic-embed-text", "prompt": "test"}'
```

### PowerShell equivalent (if you prefer pwsh on Mac):
```powershell
$body = @{
    model = "nomic-embed-text"
    prompt = "test"
} | ConvertTo-Json -Compress

(Invoke-WebRequest -Uri "https://localhost/api/embeddings" -Method POST -Body $body).Content
```

## Things to Verify / May Have Changed Since Dec 2025
- [ ] Ollama Homebrew formula version — check `brew info ollama`
- [ ] nginx default port — may conflict if something else uses 443 (need sudo or adjust)
- [ ] OpenSSL Homebrew path — confirm with `brew --prefix openssl`
- [ ] SQL Server 2025 Docker image tag — `2025-latest` should pull CU1+ (AVX fix included)
- [ ] Azure Data Studio — check if native ARM64 build is available
- [ ] nginx on port 443 requires root — either `sudo brew services start nginx` or use a higher port (e.g., 8443) and adjust SQL Server endpoint accordingly

## Architecture Flow (macOS)
```
SQL Server 2025 (Docker, port 1433)
    → HTTPS request to localhost:443
        → nginx (TLS termination, Homebrew service)
            → HTTP proxy to localhost:11434
                → Ollama (native ARM64, Homebrew service)
```

## Source
Original Windows script: Nocentino (Dec 2025)
https://www.nocentino.com/
