@echo off
REM HWPX MCP server wrapper (Windows)
REM Copyright (c) 2026 이창준, (주)파워솔루션
set SCRIPT_DIR=%~dp0
uv run --directory "%SCRIPT_DIR%" python scripts/mcp_server.py %*
