@echo off
REM HWPX MCP 통합 설치 스크립트 (Windows)
REM Copyright (c) 2026 이창준, (주)파워솔루션
REM MIT License

setlocal enabledelayedexpansion

set REPO_URL=https://github.com/cjLee-cmd/jun-skills-hwpx-v2.git
set INSTALL_DIR=%USERPROFILE%\jun-skills-hwpx-v2
set WRAPPER=%INSTALL_DIR%\run_server.bat

echo ======================================
echo  HWPX MCP 통합 설치
echo  Markdown→HWPX + HWPX 템플릿→HWPX
echo  Copyright (c) 2026 이창준, (주)파워솔루션
echo ======================================
echo.

REM ── 1. uv 설치 확인
where uv >nul 2>&1
if errorlevel 1 (
    echo ▶ uv 설치 중...
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    if errorlevel 1 (
        echo 오류: uv 설치에 실패했습니다.
        exit /b 1
    )
    set "PATH=%USERPROFILE%\.cargo\bin;%USERPROFILE%\.local\bin;%PATH%"
)
where uv >nul 2>&1
if errorlevel 1 (
    echo 오류: uv 설치 후에도 uv를 찾을 수 없습니다. 터미널을 재시작한 뒤 다시 실행하세요.
    exit /b 1
)
echo ✓ uv 확인됨

REM ── 2. git 확인
where git >nul 2>&1
if errorlevel 1 (
    echo 오류: git이 설치되어 있지 않습니다.
    exit /b 1
)

REM ── 3. 소스 클론 또는 업데이트
if exist "%INSTALL_DIR%\.git" (
    echo ▶ 기존 설치 업데이트 중...
    git -C "%INSTALL_DIR%" pull
) else (
    echo ▶ 소스 다운로드 중...
    git clone %REPO_URL% "%INSTALL_DIR%"
)
echo ✓ 설치 경로: %INSTALL_DIR%

REM ── 4. 의존성 설치
echo ▶ 의존성 설치 중...
cd /d "%INSTALL_DIR%"
uv sync
echo ✓ 의존성 설치 완료

REM ── 5. Claude Code MCP 자동 등록
set CLAUDE_JSON=%USERPROFILE%\.claude.json
where claude >nul 2>&1
if not errorlevel 1 (
    if not exist "%CLAUDE_JSON%" echo {} > "%CLAUDE_JSON%"
)
if exist "%CLAUDE_JSON%" (
    uv run python -c "import json,os; p=r'%CLAUDE_JSON%'; d=json.load(open(p)); d.setdefault('mcpServers',{})['hwpx']={'type':'stdio','command':'uv','args':['run','--directory',r'%INSTALL_DIR%'.replace(os.sep,'/') ,'python','scripts/mcp_server.py']}; json.dump(d,open(p,'w'),indent=2,ensure_ascii=False); print('✓ Claude Code MCP 등록 완료')"
) else (
    echo - Claude Code 미설치 (건너뜀^)
)

REM ── 5b. Claude Desktop MCP 자동 등록
set CLAUDE_DESKTOP=%APPDATA%\Claude\claude_desktop_config.json
if exist "%APPDATA%\Claude" (
    if not exist "%CLAUDE_DESKTOP%" echo {} > "%CLAUDE_DESKTOP%"
    uv run python -c "import json,os; p=r'%CLAUDE_DESKTOP%'; d=json.load(open(p)); d.setdefault('mcpServers',{})['hwpx']={'command':'uv','args':['run','--directory',r'%INSTALL_DIR%'.replace(os.sep,'/') ,'python','scripts/mcp_server.py']}; json.dump(d,open(p,'w'),indent=2,ensure_ascii=False); print('✓ Claude Desktop MCP 등록 완료')"
) else (
    echo - Claude Desktop 미설치 (건너뜀^)
)

REM ── 6. Gemini CLI MCP 자동 등록
set GEMINI_SETTINGS=%USERPROFILE%\.gemini\settings.json
if exist "%USERPROFILE%\.gemini" (
    if not exist "%GEMINI_SETTINGS%" echo {} > "%GEMINI_SETTINGS%"
    uv run python -c "import json; p=r'%GEMINI_SETTINGS%'; d=json.load(open(p)); d.setdefault('mcpServers',{})['hwpx']={'command':r'%WRAPPER%','args':[]}; json.dump(d,open(p,'w'),indent=2,ensure_ascii=False); print('✓ Gemini CLI MCP 등록 완료')"
) else (
    echo - Gemini CLI 미설치 (건너뜀^)
)

REM ── 7. 완료
echo.
echo ======================================
echo  설치 완료!
echo ======================================
echo.
echo ✓ 설치 경로     : %INSTALL_DIR%
echo ✓ Claude Code   : 자동 등록됨 (설치된 경우)
echo ✓ Claude Desktop: 자동 등록됨 (설치된 경우)
echo ✓ Gemini CLI    : 자동 등록됨 (설치된 경우)
echo.
echo 자세한 내용: %INSTALL_DIR%\README.md

endlocal
