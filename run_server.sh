#!/bin/bash
# HWPX MCP 서버 실행 래퍼 (macOS / Linux)
# Copyright (c) 2026 이창준, (주)파워솔루션
# MIT License

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

if [ -f "/opt/homebrew/bin/uv" ]; then
    UV="/opt/homebrew/bin/uv"
elif [ -f "$HOME/.local/bin/uv" ]; then
    UV="$HOME/.local/bin/uv"
else
    UV="uv"
fi

exec "$UV" run --directory "$PROJECT_DIR" python scripts/mcp_server.py "$@"
