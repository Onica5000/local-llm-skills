---
name: network-crypto
description: Use for HTTP requests, SSH/SCP/SFTP remote access, key generation, TLS certificates, hashing, and encryption with curl, OpenSSH, and OpenSSL. Plus built-in Windows networking (netsh, ipconfig).
---

# network-crypto

## HTTP â€” use `curl.exe` (NOT `curl`, which is an alias in PowerShell)
```powershell
curl.exe -s https://api.example.com/data            # GET
curl.exe -s https://api.example.com/data | ConvertFrom-Json
curl.exe -X POST -H "Content-Type: application/json" -d '{"k":"v"}' https://api...
curl.exe -L -o file.zip https://example.com/file.zip   # download, follow redirects
curl.exe -I https://example.com                      # headers only
```
> To READ web pages or search, prefer the `web-search` skill â€” it returns clean text.

## SSH / SCP / SFTP (OpenSSH 9.5)
```powershell
ssh user@host
ssh -i {{USERPROFILE}}\.ssh\id_ed25519 user@host
scp local.txt user@host:/remote/path/
scp user@host:/remote/file.txt .
sftp user@host
ssh-keygen -t ed25519 -C "you@example.com"          # generate a key
```

## OpenSSL 3.5 â€” crypto, certs, hashing
```powershell
openssl rand -hex 32                                  # random key/token
openssl dgst -sha256 file.bin                         # hash a file
openssl genrsa -out key.pem 2048                      # RSA private key
openssl req -new -x509 -key key.pem -out cert.pem -days 365   # self-signed cert
openssl x509 -in cert.pem -noout -text                # inspect a cert
openssl enc -aes-256-cbc -salt -in f -out f.enc       # encrypt (asks for password)
```

## Built-in Windows networking
```powershell
ipconfig /all
netsh wlan show profiles
Test-NetConnection host -Port 443     # PowerShell's connectivity test
```

## Rules
- Always `curl.exe`, never bare `curl`, in PowerShell.
- Keep private keys in `{{USERPROFILE}}\.ssh\`; never print private key contents to chat.

