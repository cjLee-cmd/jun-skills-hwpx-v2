# jun-skills-hwpx-v2

**Unified HWPX (Hangul Word Processor) MCP Server**

Markdown 문서를 HWPX로 변환하거나, 기존 HWPX 템플릿을 분석하여 서식을 유지하면서 새로운 내용으로 문서를 생성하는 통합 MCP 서버입니다.

> Copyright (c) 2026 이창준, (주)파워솔루션 | MIT License

---

## 두 가지 워크플로우

### 1. Markdown → HWPX (템플릿 불필요)

Markdown 파일을 바로 HWPX 문서로 변환합니다. 표지, 머리글/바닥글, 자동 번호 매기기를 지원합니다.

```
"report.md를 한글 문서로 변환해줘"
```

**사용 도구**: `convert_md_to_hwpx`

### 2. HWPX 템플릿 → HWPX (서식 유지)

기존 HWPX 문서의 서식(글꼴, 여백, 스타일)을 그대로 유지하면서 내용만 교체합니다. 공문, 보고서, 회의록 등 정해진 양식이 있을 때 사용합니다.

```
"이 공문 양식에 맞춰서 새 문서를 만들어줘"
```

**사용 도구**: `analyze_hwpx` → `extract_hwpx_xml` → `build_hwpx` → `validate_hwpx` → `page_guard_hwpx`

---

## 설치

### 자동 설치 (권장)

**macOS / Linux:**
```bash
curl -LsSf https://raw.githubusercontent.com/cjLee-cmd/jun-skills-hwpx-v2/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/cjLee-cmd/jun-skills-hwpx-v2/main/install.bat" -OutFile "$env:TEMP\install.bat"; & "$env:TEMP\install.bat"
```

설치 스크립트가 자동으로 수행하는 작업:
- `uv` 설치 (없는 경우)
- 소스 다운로드 (`~/jun-skills-hwpx-v2`)
- 의존성 설치 (`uv sync`)
- MCP 서버 자동 등록:
  - **Claude Code** (`~/.claude.json`)
  - **Claude Desktop** (`claude_desktop_config.json`)
  - **Gemini CLI** (`~/.gemini/settings.json`)

### 수동 설치

```bash
git clone https://github.com/cjLee-cmd/jun-skills-hwpx-v2.git ~/jun-skills-hwpx-v2
cd ~/jun-skills-hwpx-v2
uv sync
```

MCP 설정 파일에 다음을 추가:

```json
{
  "mcpServers": {
    "hwpx": {
      "command": "uv",
      "args": ["run", "--directory", "/path/to/jun-skills-hwpx-v2", "python", "scripts/mcp_server.py"]
    }
  }
}
```

| 클라이언트 | 설정 파일 경로 |
|-----------|--------------|
| Claude Code | `~/.claude.json` |
| Claude Desktop (macOS) | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Claude Desktop (Windows) | `%APPDATA%\Claude\claude_desktop_config.json` |
| Gemini CLI | `~/.gemini/settings.json` |

---

## MCP 도구 목록

| 도구 | 설명 |
|------|------|
| `convert_md_to_hwpx` | Markdown → HWPX 변환 (표, 코드블록, 리스트, 인용문, 표지, 머리글/바닥글 지원) |
| `analyze_hwpx` | HWPX 문서 구조 분석 (글꼴, 스타일, 레이아웃 추출) |
| `extract_hwpx_xml` | HWPX에서 header.xml / section0.xml 추출 |
| `build_hwpx` | 템플릿 + XML → HWPX 조립 |
| `validate_hwpx` | HWPX 구조 무결성 검증 |
| `page_guard_hwpx` | 레퍼런스 대비 페이지 수 드리프트 검사 |
| `extract_text_hwpx` | HWPX에서 텍스트 추출 |

---

## CLI 직접 실행

```bash
cd ~/jun-skills-hwpx-v2

# Markdown → HWPX
uv run python scripts/md2hwpx.py input.md output.hwpx --title "보고서 제목"

# HWPX 분석
uv run python scripts/analyze_template.py template.hwpx
```

---

## 사용 예시

### Claude / Gemini에서 사용

```
# Markdown → HWPX (템플릿 없이)
"이 마크다운 파일을 한글 문서로 변환해줘"
"report.md를 HWPX로 만들어줘. 제목은 '월간 보고서'"

# HWPX 템플릿 기반
"이 한글 문서를 분석해줘" (analyze_hwpx)
"이 양식에 맞춰 새 문서를 만들어줘" (전체 워크플로우)
"공문 양식으로 문서를 작성해줘" (내장 템플릿 사용)
```

---

## 내장 템플릿

`templates/` 폴더에 다음 양식이 포함되어 있습니다:

| 템플릿 | 설명 |
|--------|------|
| `base/` | 기본 스켈레톤 |
| `gonmun/` | 공문 |
| `report/` | 보고서 |
| `minutes/` | 회의록 |
| `proposal/` | 제안서 |

---

## 요구 사항

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) (설치 스크립트가 자동 설치)
- git

---

## 라이선스

MIT License - 자유롭게 사용, 수정, 배포할 수 있습니다.
