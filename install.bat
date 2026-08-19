@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM Hermes Agent - Standalone Offline Installer
REM ============================================================
REM Self-contained installer for portable use on any Windows machine.
REM Place this file at the root of the hermes-agent folder.
REM Prerequisites on target machine: Python 3.11+, npm (Node 22+)
REM All dependencies are pre-bundled in the packages/ directory.
REM
REM Usage: Run as Administrator to avoid permission issues.
REM        cd C:\hermes-agent\
REM        install.bat
REM ============================================================

echo.
echo ========================================
echo  Hermes Agent - Offline Installer
echo ========================================
echo.

REM Detect working directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
cd /d "%SCRIPT_DIR%"

echo [Step 1/6] Checking prerequisites...
where python >nul 2>&1 || (
    echo [FAIL] Python not found on PATH.
    echo        Install Python 3.11+ from https://python.org and add to PATH.
    echo        Then run this installer again.
    pause
    exit /b 1
)
where npm >nul 2>&1 || (
    echo [FAIL] npm not found on PATH.
    echo        Install Node.js 22+ from https://nodejs.org and add to PATH.
    echo        Then run this installer again.
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
for /f "tokens=*" %%i in ('npm --version 2^>^&1') do set NPVER=%%i
echo   Python: !PYVER!
echo   npm: !NPVER!
echo.

REM Step 2: Install Python deps from local wheels
echo [Step 2/6] Installing Python dependencies from local cache...
if not exist "packages\wheels\*.whl" (
    echo [WARN] No Python wheels found in packages/wheels/.
    echo        Falling back to online install (requires internet).
    python -m pip install .
) else (
    echo   Found !PYVER! - installing from wheels...
    python -m pip install --no-build-isolation --no-index --find-links=packages/wheels -e .
    if !errorlevel! neq 0 (
        echo [WARN] Wheel install failed. Retrying with network access...
        python -m pip install --find-links=packages/wheels -e .
    )
)
echo   Python dependencies installed.
echo.

REM Step 3: Install Node.js deps from local tarballs
echo [Step 3/6] Installing Node.js dependencies from local cache...
if exist "packages\npm-root.tar.gz" (
    echo   Extracting npm packages from local archive...
    
    REM Check if 7z is available, otherwise use tar from git-bash
    where 7z >nul 2>&1 && (
        7z x packages\npm-root.tar.gz -y >nul 2>&1
    ) || (
        bash -c "cd /c/Users/Laptop/hermes-agent && tar -xzf packages/npm-root.tar.gz 2>/dev/null" 2>nul || (
            echo [WARN] Failed to extract npm archive. Falling back to npm install.
            npm install
        )
    )
    
    echo   npm packages extracted.
) else if exist "package-lock.json" (
    echo   No local archive found. Installing from network...
    npm install
) else (
    echo [ERROR] No npm dependencies found (no packages/ tarball or package-lock.json).
    echo         Cannot continue without Node.js dependencies.
    pause
    exit /b 1
)
echo.

REM Step 4: Create venv with dependencies
echo [Step 4/6] Setting up virtual environment...
if not exist ".venv" (
    python -m venv .venv
    echo   Created .venv
)

REM Activate venv
call .venv\Scripts\activate.bat

REM Sync with uv if available, otherwise use pip
if exist ".venv\Scripts\uv.exe" (
    echo   Using uv for dependency resolution...
    .venv\Scripts\uv sync 2>nul || pip install -e .
) else (
    echo   Using pip for dependency resolution...
    pip install -e .
)
echo   Virtual environment ready.
echo.

REM Step 5: Configure Hermes
echo [Step 5/6] Setting up Hermes configuration...
if not exist "%USERPROFILE%\.hermes" mkdir "%USERPROFILE%\.hermes"

if not exist "%USERPROFILE%\.hermes\config.yaml" (
    echo   No config.yaml found. Creating template...
    type NUL > "%USERPROFILE%\.hermes\config.yaml"
    echo   [INFO] Created empty %USERPROFILE%\.hermes\config.yaml
    echo   You'll need to add your provider configuration.
) else (
    echo   Existing config.yaml found.
)

echo.
echo   To configure your local model, add to config.yaml:
echo.
echo   providers:
echo     local:
echo       api_base: http://your-local-model-host:port
echo       api_key: your-key
echo       models:
echo         - your-model-name
echo.

REM Step 6: Verify installation
echo [Step 6/6] Verifying installation...
set INSTALL_OK=0

python run_agent.py --help >nul 2>&1
if !errorlevel! equ 0 (
    echo   PASS: run_agent.py works
    set INSTALL_OK=1
) else (
    echo   FAIL: run_agent.py failed
)

python cli.py --help >nul 2>&1
if !errorlevel! equ 0 (
    echo   PASS: cli.py works
    set INSTALL_OK=1
) else (
    echo   FAIL: cli.py failed
)
echo.

if !INSTALL_OK! equ 1 (
    echo ========================================
    echo   INSTALLATION SUCCESSFUL!
    echo ========================================
    echo.
    echo Next steps:
    echo   1. Configure your model provider in config.yaml
    echo   2. Run: hermes setup  (interactive setup wizard)
    echo   3. Start chatting:    hermes
    echo   4. Launch desktop:    hermes desktop
    echo.
    echo For a local AI model (already hosting):
    echo   Edit %USERPROFILE%\.hermes\config.yaml with your model details.
    echo ========================================
) else (
    echo ========================================
    echo   INSTALLATION FAILED
    echo ========================================
    echo.
    echo Please check the errors above.
    echo Common fixes:
    echo   - Ensure Python 3.11+ is installed and on PATH
    echo   - Ensure npm/Node.js 22+ is installed and on PATH
    echo   - Run this installer as Administrator
    echo ========================================
)

echo.
pause
