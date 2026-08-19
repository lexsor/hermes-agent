# Hermes Agent - Standalone Install

This is a fully self-contained installation of Hermes Agent (v0.20.4) ready to run on any Windows machine.

## What's Included

- Full Hermes Agent source code
- Python dependencies: 40MB of pre-downloaded wheels (64 packages) in `packages/wheels/`
- Node.js dependencies: 313MB of pre-bundled packages in `packages/*.tar.gz`
- One-click installer: `install.bat`

## Quick Start

1. Copy this entire folder to your target machine
2. Double-click `install.bat` (run as Administrator)
3. Follow the prompts

That's it. All dependencies are installed from the local cache — no internet required.

## Configuration

After installation, configure your model provider:

```yaml
# Edit %USERPROFILE%\.hermes\config.yaml
providers:
  local:
    api_base: http://localhost:port
    api_key: your-key
    models:
      - your-model-name
```

Then run:

```
hermes setup    # Interactive wizard
hermes          # Start chatting
hermes desktop  # Launch desktop app
```

## Manual Install (if install.bat fails)

### Python
```
python -m pip install --no-index --find-links=packages\wheels .
```

### Node.js
```
npm install
```

## File Sizes

- Total package cache: ~354MB (compressed)
- Python wheels: 40MB
- npm-root: 180MB
- desktop node_modules: 133MB

## Troubleshooting

**"Python not found"** - Install Python 3.11+ and add to PATH
**"npm not found"** - Install Node.js 22+ and add to PATH
**Wheel install failed** - Retries with network access, make sure you have internet on first install
**Permission denied** - Run installer as Administrator
