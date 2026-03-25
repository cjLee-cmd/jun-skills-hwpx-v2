---
name: jun-hwpx2hwpx
description: "한글(HWPX) 문서 생성/읽기/편집 스킬. .hwpx 파일, 한글 문서, Hancom, OWPML 관련 요청 시 사용."
---

# HWPX 문서 스킬 — 레퍼런스 복원 우선(XML-first) 워크플로우

한글(Hancom Office)의 HWPX 파일을 **XML 직접 작성** 중심으로 생성, 편집, 읽기할 수 있는 스킬.
HWPX는 ZIP 기반 XML 컨테이너(OWPML 표준)이다. python-hwpx API의 서식 버그를 완전히 우회하며, 세밀한 서식 제어가 가능하다.

## 기본 동작 모드 (필수): 첨부 HWPX 분석 → 고유 XML 복원(99% 근접) → 요청 반영 재작성

사용자가 `.hwpx`를 첨부한 경우, 이 스킬은 아래 순서를 **기본값**으로 따른다.

1. **레퍼런스 확보**: 첨부된 HWPX를 기준 문서로 사용 (`/mnt/user-data/uploads/` 경로)
2. **심층 분석/추출**: `hwpx:analyze_hwpx` + `hwpx:extract_hwpx_xml`로 스타일/구조 파악 및 XML 추출
3. **구조 복원**: header 스타일 ID/표 구조/셀 병합/여백/문단 흐름을 최대한 동일하게 유지
4. **요청 반영 재작성**: 추출된 section0.xml을 수정해 텍스트/데이터만 교체, 구조는 보존
5. **빌드/검증**: `hwpx:build_hwpx` + `hwpx:validate_hwpx`로 결과 산출 및 무결성 확인
6. **쪽수 가드(필수)**: `hwpx:page_guard_hwpx`로 레퍼런스 대비 페이지 드리프트 위험 검사

### 99% 근접 복원 기준 (실무 체크리스트)

- `charPrIDRef`, `paraPrIDRef`, `borderFillIDRef` 참조 체계 동일
- 표의 `rowCnt`, `colCnt`, `colSpan`, `rowSpan`, `cellSz`, `cellMargin` 동일
- 문단 순서, 문단 수, 주요 빈 줄/구획 위치 동일
- 페이지/여백/섹션(secPr) 동일
- 변경은 사용자 요청 범위(본문 텍스트, 값, 항목명 등)로 제한

### 쪽수 동일(100%) 필수 기준

- 사용자가 레퍼런스를 제공한 경우 **결과 문서의 최종 쪽수는 레퍼런스와 동일해야 한다**
- 쪽수가 늘어날 가능성이 보이면 먼저 텍스트를 압축/요약해서 기존 레이아웃에 맞춘다
- 사용자 명시 요청 없이 `hp:p`, `hp:tbl`, `rowCnt`, `colCnt`, `pageBreak`, `secPr`를 변경하지 않는다
- `hwpx:validate_hwpx` 통과만으로 완료 처리하지 않는다. 반드시 `hwpx:page_guard_hwpx`도 통과해야 한다
- `hwpx:page_guard_hwpx` 실패 시 결과를 완료로 제출하지 않고, 원인(길이 과다/구조 변경)을 수정 후 재빌드한다
- 가능하면 한글(또는 사용자의 확인) 기준 최종 쪽수 값을 확인하고 레퍼런스와 일치 여부를 재확인한다

### 기본 실행 순서 (첨부 레퍼런스가 있을 때)

```
# 1) 레퍼런스 분석
hwpx:analyze_hwpx(hwpx_path="/mnt/user-data/uploads/reference.hwpx")

# 2) XML 추출 (header.xml + section0.xml)
hwpx:extract_hwpx_xml(
    hwpx_path="/mnt/user-data/uploads/reference.hwpx",
    extract_dir="/tmp/ref_xml"
)
# → /tmp/ref_xml/header.xml, /tmp/ref_xml/section0.xml 생성

# 3) /tmp/ref_xml/section0.xml을 읽어 수정 → /tmp/new_section0.xml 저장
#    (구조 유지, 텍스트/데이터만 요청에 맞게 수정)

# 4) 복원 빌드
hwpx:build_hwpx(
    output_hwpx="/tmp/result.hwpx",
    header_xml="/tmp/ref_xml/header.xml",
    section_xml="/tmp/new_section0.xml"
)

# 5) 검증
hwpx:validate_hwpx(hwpx_path="/tmp/result.hwpx")

# 6) 쪽수 드리프트 가드 (필수)
hwpx:page_guard_hwpx(
    reference_hwpx="/mnt/user-data/uploads/reference.hwpx",
    output_hwpx="/tmp/result.hwpx"
)

# 7) 최종 출력
# cp /tmp/result.hwpx /mnt/user-data/outputs/result.hwpx
# present_files(["/mnt/user-data/outputs/result.hwpx"])
```

---

## MCP 도구 매핑 (Claude.ai 환경)

> Claude.ai에서는 Python 스크립트를 직접 실행할 수 없다.
> 아래 MCP 도구를 사용한다. 모든 도구는 `hwpx:` 네임스페이스로 제공된다.

| 역할 | MCP 도구 | 주요 파라미터 |
|------|----------|-------------|
| HWPX 구조 분석 | `hwpx:analyze_hwpx` | `hwpx_path` |
| XML 추출 (header + section) | `hwpx:extract_hwpx_xml` | `hwpx_path`, `extract_dir` |
| HWPX 조립 (빌드) | `hwpx:build_hwpx` | `output_hwpx`, `template`, `section_xml`, `header_xml`, `title`, `creator` |
| 구조 검증 | `hwpx:validate_hwpx` | `hwpx_path` |
| 쪽수 드리프트 검사 | `hwpx:page_guard_hwpx` | `reference_hwpx`, `output_hwpx`, `max_paragraph_delta`(기본 0.25), `max_text_delta`(기본 0.15) |
| 텍스트 추출 | `hwpx:extract_text_hwpx` | `hwpx_path`, `include_tables`(기본 true), `fmt`("text"\|"markdown") |
| MD → HWPX 직접 변환 | `hwpx:convert_md_to_hwpx` | `input_md`, `output_hwpx`, `title`, `author`, `language` |

### Claude Code 환경에서의 스크립트 ↔ MCP 도구 대응표

| Python 스크립트 (Claude Code) | MCP 도구 (Claude.ai) |
|-------------------------------|----------------------|
| `python3 analyze_template.py ref.hwpx` | `hwpx:analyze_hwpx(hwpx_path=...)` |
| `python3 analyze_template.py ref.hwpx --extract-header h.xml --extract-section s.xml` | `hwpx:extract_hwpx_xml(hwpx_path=..., extract_dir=...)` |
| `python3 build_hwpx.py --header h.xml --section s.xml --output out.hwpx` | `hwpx:build_hwpx(output_hwpx=..., header_xml=..., section_xml=...)` |
| `python3 build_hwpx.py --template gonmun --output out.hwpx` | `hwpx:build_hwpx(output_hwpx=..., template="gonmun")` |
| `python3 validate.py out.hwpx` | `hwpx:validate_hwpx(hwpx_path=...)` |
| `python3 page_guard.py --reference ref.hwpx --output out.hwpx` | `hwpx:page_guard_hwpx(reference_hwpx=..., output_hwpx=...)` |
| `python3 text_extract.py doc.hwpx --format markdown` | `hwpx:extract_text_hwpx(hwpx_path=..., fmt="markdown")` |
| `python3 scripts/md2hwpx.py input.md output.hwpx` | `hwpx:convert_md_to_hwpx(input_md=..., output_hwpx=...)` |

### 파일 경로 규칙 (Claude.ai)

- **업로드된 HWPX**: `/mnt/user-data/uploads/<filename>.hwpx`
- **작업 임시 파일**: `/tmp/<name>.hwpx`, `/tmp/<name>.xml`
- **최종 출력**: `/mnt/user-data/outputs/<name>.hwpx` → `present_files()`로 전달

---

## 디렉토리 구조

```
jun-skills-hwpx-v2/
├── SKILL.md                              # 이 파일
├── scripts/
│   ├── office/
│   │   ├── unpack.py                     # HWPX → 디렉토리 (XML pretty-print)
│   │   └── pack.py                       # 디렉토리 → HWPX
│   ├── build_hwpx.py                     # 템플릿 + XML → .hwpx 조립 (핵심)
│   ├── analyze_template.py               # HWPX 심층 분석 (레퍼런스 기반 생성용)
│   ├── validate.py                       # HWPX 구조 검증
│   ├── page_guard.py                     # 레퍼런스 대비 페이지 드리프트 위험 검사
│   └── text_extract.py                   # 텍스트 추출
├── templates/
│   ├── base/                             # 베이스 템플릿 (Skeleton 기반)
│   │   ├── mimetype, META-INF/*, version.xml, settings.xml, Preview/*
│   │   └── Contents/ (header.xml, section0.xml, content.hpf)
│   ├── gonmun/                           # 공문 오버레이 (header.xml, section0.xml)
│   ├── report/                           # 보고서 오버레이
│   ├── minutes/                          # 회의록 오버레이
│   └── proposal/                         # 제안서/사업개요 오버레이 (색상 헤더바, 번호 배지)
└── references/
    └── hwpx-format.md                    # OWPML XML 요소 레퍼런스
```

---

## 워크플로우 1: XML-first 문서 생성 (레퍼런스 파일이 없을 때만)

### 흐름

1. **템플릿 선택** (base/gonmun/report/minutes/proposal)
2. **section0.xml 작성** (본문 내용)
3. **(선택) header.xml 수정** (새 스타일 추가 필요 시)
4. **`hwpx:build_hwpx`로 빌드**
5. **`hwpx:validate_hwpx`로 검증**

> 원칙: 사용자가 레퍼런스 HWPX를 제공한 경우에는 이 워크플로우 대신 상단의 "기본 동작 모드(레퍼런스 복원 우선)"를 사용한다.

### MCP 도구 사용법

```
# 빈 문서 (base 템플릿)
hwpx:build_hwpx(output_hwpx="/tmp/result.hwpx")

# 템플릿 사용
hwpx:build_hwpx(output_hwpx="/tmp/result.hwpx", template="gonmun")

# 커스텀 section0.xml 오버라이드
hwpx:build_hwpx(
    output_hwpx="/tmp/result.hwpx",
    template="gonmun",
    section_xml="/tmp/my_section0.xml"
)

# header도 오버라이드
hwpx:build_hwpx(
    output_hwpx="/tmp/result.hwpx",
    header_xml="/tmp/my_header.xml",
    section_xml="/tmp/my_section0.xml"
)

# 메타데이터 포함
hwpx:build_hwpx(
    output_hwpx="/tmp/result.hwpx",
    template="report",
    section_xml="/tmp/my.xml",
    title="제목",
    creator="작성자"
)
```

### 실전 패턴: section0.xml을 bash_tool로 작성 → 빌드

```bash
# 1. section0.xml을 임시파일로 작성
cat > /tmp/section0.xml << 'XMLEOF'
<?xml version='1.0' encoding='UTF-8'?>
<hs:sec xmlns:hp="http://www.hancom.co.kr/hwpml/2011/paragraph"
        xmlns:hs="http://www.hancom.co.kr/hwpml/2011/section">
  <!-- secPr 포함 첫 문단 (base/section0.xml에서 복사) -->
  <hp:p id="1000000002" paraPrIDRef="0" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
    <hp:run charPrIDRef="0">
      <hp:t>본문 내용</hp:t>
    </hp:run>
  </hp:p>
</hs:sec>
XMLEOF
```

```
# 2. 빌드
hwpx:build_hwpx(output_hwpx="/tmp/result.hwpx", section_xml="/tmp/section0.xml")
```

---

## section0.xml 작성 가이드

### 필수 구조

section0.xml의 첫 문단(`<hp:p>`)의 첫 런(`<hp:run>`)에 반드시 `<hp:secPr>`과 `<hp:colPr>` 포함:

```xml
<hp:p id="1000000001" paraPrIDRef="0" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
  <hp:run charPrIDRef="0">
    <hp:secPr ...>
      <!-- 페이지 크기, 여백, 각주/미주 설정 등 -->
    </hp:secPr>
    <hp:ctrl>
      <hp:colPr id="" type="NEWSPAPER" layout="LEFT" colCount="1" sameSz="1" sameGap="0"/>
    </hp:ctrl>
  </hp:run>
  <hp:run charPrIDRef="0"><hp:t/></hp:run>
</hp:p>
```

**Tip**: `templates/base/Contents/section0.xml` 의 첫 문단을 그대로 복사하면 된다.

### 문단

```xml
<hp:p id="고유ID" paraPrIDRef="문단스타일ID" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
  <hp:run charPrIDRef="글자스타일ID">
    <hp:t>텍스트 내용</hp:t>
  </hp:run>
</hp:p>
```

### 빈 줄

```xml
<hp:p id="고유ID" paraPrIDRef="0" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
  <hp:run charPrIDRef="0"><hp:t/></hp:run>
</hp:p>
```

### 서식 혼합 런 (한 문단에 여러 스타일)

```xml
<hp:p id="고유ID" paraPrIDRef="0" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
  <hp:run charPrIDRef="0"><hp:t>일반 텍스트 </hp:t></hp:run>
  <hp:run charPrIDRef="7"><hp:t>볼드 텍스트</hp:t></hp:run>
  <hp:run charPrIDRef="0"><hp:t> 다시 일반</hp:t></hp:run>
</hp:p>
```

### 표 작성법

```xml
<hp:p id="고유ID" paraPrIDRef="0" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0">
  <hp:run charPrIDRef="0">
    <hp:tbl id="고유ID" zOrder="0" numberingType="TABLE" textWrap="TOP_AND_BOTTOM"
            textFlow="BOTH_SIDES" lock="0" dropcapstyle="None" pageBreak="CELL"
            repeatHeader="0" rowCnt="행수" colCnt="열수" cellSpacing="0"
            borderFillIDRef="3" noAdjust="0">
      <hp:sz width="42520" widthRelTo="ABSOLUTE" height="전체높이" heightRelTo="ABSOLUTE" protect="0"/>
      <hp:pos treatAsChar="1" affectLSpacing="0" flowWithText="1" allowOverlap="0"
              holdAnchorAndSO="0" vertRelTo="PARA" horzRelTo="COLUMN" vertAlign="TOP"
              horzAlign="LEFT" vertOffset="0" horzOffset="0"/>
      <hp:outMargin left="0" right="0" top="0" bottom="0"/>
      <hp:inMargin left="0" right="0" top="0" bottom="0"/>
      <hp:tr>
        <hp:tc name="" header="0" hasMargin="0" protect="0" editable="0" dirty="1" borderFillIDRef="4">
          <hp:subList id="" textDirection="HORIZONTAL" lineWrap="BREAK" vertAlign="CENTER"
                     linkListIDRef="0" linkListNextIDRef="0" textWidth="0" textHeight="0"
                     hasTextRef="0" hasNumRef="0">
            <hp:p paraPrIDRef="21" styleIDRef="0" pageBreak="0" columnBreak="0" merged="0" id="고유ID">
              <hp:run charPrIDRef="9"><hp:t>헤더 셀</hp:t></hp:run>
            </hp:p>
          </hp:subList>
          <hp:cellAddr colAddr="0" rowAddr="0"/>
          <hp:cellSpan colSpan="1" rowSpan="1"/>
          <hp:cellSz width="열너비" height="행높이"/>
          <hp:cellMargin left="0" right="0" top="0" bottom="0"/>
        </hp:tc>
        <!-- 나머지 셀... -->
      </hp:tr>
    </hp:tbl>
  </hp:run>
</hp:p>
```

### 표 크기 계산

- **A4 본문폭**: 42520 HWPUNIT = 59528(용지) - 8504×2(좌우여백)
- **열 너비 합 = 본문폭** (42520)
- 예: 3열 균등 → 14173 + 14173 + 14174 = 42520
- 예: 2열 (라벨:내용 = 1:4) → 8504 + 34016 = 42520
- **행 높이**: 셀당 보통 2400~3600 HWPUNIT

### ID 규칙

- 문단 id: `1000000001`부터 순차 증가
- 표 id: `1000000099` 등 별도 범위 사용 권장
- 모든 id는 문서 내 고유해야 함

---

## header.xml 수정 가이드

### 커스텀 스타일 추가 방법

1. `hwpx:extract_hwpx_xml`로 레퍼런스의 header.xml 추출
2. 필요한 charPr/paraPr/borderFill 추가
3. 각 그룹의 `itemCnt` 속성 업데이트

### charPr 추가 예시 (볼드 14pt)

```xml
<hh:charPr id="8" height="1400" textColor="#000000" shadeColor="none"
           useFontSpace="0" useKerning="0" symMark="NONE" borderFillIDRef="2">
  <hh:fontRef hangul="1" latin="1" hanja="1" japanese="1" other="1" symbol="1" user="1"/>
  <hh:ratio hangul="100" latin="100" hanja="100" japanese="100" other="100" symbol="100" user="100"/>
  <hh:spacing hangul="0" latin="0" hanja="0" japanese="0" other="0" symbol="0" user="0"/>
  <hh:relSz hangul="100" latin="100" hanja="100" japanese="100" other="100" symbol="100" user="100"/>
  <hh:offset hangul="0" latin="0" hanja="0" japanese="0" other="0" symbol="0" user="0"/>
  <hh:bold/>
  <hh:underline type="NONE" shape="SOLID" color="#000000"/>
  <hh:strikeout shape="NONE" color="#000000"/>
  <hh:outline type="NONE"/>
  <hh:shadow type="NONE" color="#C0C0C0" offsetX="10" offsetY="10"/>
</hh:charPr>
```

### 폰트 참조 체계

- `fontRef` 값은 `fontfaces`에 정의된 font id
- `hangul="0"` → 함초롬돋움 (고딕)
- `hangul="1"` → 함초롬바탕 (명조)
- 7개 언어 모두 동일하게 설정

### paraPr 추가 시 주의

- 반드시 `hp:switch` 구조 포함 (`hp:case` + `hp:default`)
- `hp:case`와 `hp:default`의 값은 보통 동일 (또는 default가 2배)
- `borderFillIDRef="2"` 유지

---

## 템플릿별 스타일 ID 맵

### base (기본)

| ID | 유형 | 설명 |
|----|------|------|
| charPr 0 | 글자 | 10pt 함초롬바탕, 기본 |
| charPr 1 | 글자 | 10pt 함초롬돋움 |
| charPr 2~6 | 글자 | Skeleton 기본 스타일 |
| paraPr 0 | 문단 | JUSTIFY, 160% 줄간격 |
| paraPr 1~19 | 문단 | Skeleton 기본 (개요, 각주 등) |
| borderFill 1 | 테두리 | 없음 (페이지 보더) |
| borderFill 2 | 테두리 | 없음 + 투명배경 (참조용) |

### gonmun (공문) — base + 추가

| ID | 유형 | 설명 |
|----|------|------|
| charPr 7 | 글자 | 22pt 볼드 함초롬바탕 (기관명/제목) |
| charPr 8 | 글자 | 16pt 볼드 함초롬바탕 (서명자) |
| charPr 9 | 글자 | 8pt 함초롬바탕 (하단 연락처) |
| charPr 10 | 글자 | 10pt 볼드 함초롬바탕 (표 헤더) |
| paraPr 20 | 문단 | CENTER, 160% 줄간격 |
| paraPr 21 | 문단 | CENTER, 130% (표 셀) |
| paraPr 22 | 문단 | JUSTIFY, 130% (표 셀) |
| borderFill 3 | 테두리 | SOLID 0.12mm 4면 |
| borderFill 4 | 테두리 | SOLID 0.12mm + #D6DCE4 배경 |

### report (보고서) — base + 추가

| ID | 유형 | 설명 |
|----|------|------|
| charPr 7 | 글자 | 20pt 볼드 (문서 제목) |
| charPr 8 | 글자 | 14pt 볼드 (소제목) |
| charPr 9 | 글자 | 10pt 볼드 (표 헤더) |
| charPr 10 | 글자 | 10pt 볼드+밑줄 (강조 텍스트) |
| charPr 11 | 글자 | 9pt 함초롬바탕 (소형/각주) |
| charPr 12 | 글자 | 16pt 볼드 함초롬바탕 (1줄 제목) |
| charPr 13 | 글자 | 12pt 볼드 함초롬돋움 (섹션 헤더) |
| paraPr 20~22 | 문단 | CENTER/JUSTIFY 변형 |
| paraPr 23 | 문단 | RIGHT 정렬, 160% 줄간격 |
| paraPr 24 | 문단 | JUSTIFY, left 600 (□ 체크항목 들여쓰기) |
| paraPr 25 | 문단 | JUSTIFY, left 1200 (하위항목 ①②③ 들여쓰기) |
| paraPr 26 | 문단 | JUSTIFY, left 1800 (깊은 하위항목 - 들여쓰기) |
| paraPr 27 | 문단 | LEFT, 상하단 테두리선 (섹션 헤더용), prev 400 |
| borderFill 3 | 테두리 | SOLID 0.12mm 4면 |
| borderFill 4 | 테두리 | SOLID 0.12mm + #DAEEF3 배경 |
| borderFill 5 | 테두리 | 상단 0.4mm 굵은선 + 하단 0.12mm 얇은선 (섹션 헤더) |

**들여쓰기 규칙**: 공백 문자가 아닌 반드시 paraPr의 left margin 사용. □ 항목은 paraPr 24, 하위 ①②③ 는 paraPr 25, 깊은 - 항목은 paraPr 26.

**섹션 헤더 규칙**: paraPr 27 + charPr 13 조합. 문단 테두리(borderFillIDRef="5")로 상단 굵은선 + 하단 얇은선 자동 표시.

### minutes (회의록) — base + 추가

| ID | 유형 | 설명 |
|----|------|------|
| charPr 7 | 글자 | 18pt 볼드 (제목) |
| charPr 8 | 글자 | 12pt 볼드 (섹션 라벨) |
| charPr 9 | 글자 | 10pt 볼드 (표 헤더) |
| paraPr 20~22 | 문단 | CENTER/JUSTIFY 변형 |
| borderFill 3 | 테두리 | SOLID 0.12mm 4면 |
| borderFill 4 | 테두리 | SOLID 0.12mm + #E2EFDA 배경 |

### proposal (제안서/사업개요) — base + 추가

시각적 구분이 필요한 공식 문서용. 색상 배경 헤더바와 번호 배지를 표(table) 기반 레이아웃으로 구현.

| ID | 유형 | 설명 |
|----|------|------|
| charPr 7 | 글자 | 20pt 볼드 함초롬바탕 (문서 제목) |
| charPr 8 | 글자 | 14pt 볼드 함초롬바탕 (소제목) |
| charPr 9 | 글자 | 10pt 볼드 함초롬바탕 (표 헤더) |
| charPr 10 | 글자 | 14pt 볼드 흰색 함초롬돋움 (대항목 번호, 녹색 배경) |
| charPr 11 | 글자 | 11pt 볼드 흰색 함초롬돋움 (소항목 번호, 파란 배경) |
| paraPr 20 | 문단 | CENTER, 160% 줄간격 |
| paraPr 21 | 문단 | CENTER, 130% (표 셀) |
| paraPr 22 | 문단 | JUSTIFY, 130% (표 셀) |
| borderFill 3 | 테두리 | SOLID 0.12mm 4면 |
| borderFill 4 | 테두리 | SOLID 0.12mm + #DAEEF3 배경 |
| borderFill 5 | 테두리 | 올리브녹색 배경 #7B8B3D (대항목 번호 셀) |
| borderFill 6 | 테두리 | 연한 회색 배경 #F2F2F2 + 회색 테두리 (대항목 제목 셀) |
| borderFill 7 | 테두리 | 파란색 배경 #4472C4 (소항목 번호 배지) |
| borderFill 8 | 테두리 | 하단 테두리만 #D0D0D0 (소항목 제목 영역) |

#### proposal 레이아웃 패턴

**대항목 헤더** (2셀 표: 번호 + 제목):
```xml
<!-- borderFillIDRef="5" + charPrIDRef="10" → 녹색배경 흰색 로마숫자 -->
<!-- borderFillIDRef="6" + charPrIDRef="8"  → 회색배경 검정 볼드 제목 -->
```

**소항목 헤더** (2셀 표: 번호배지 + 제목):
```xml
<!-- borderFillIDRef="7" + charPrIDRef="11" → 파란배경 흰색 아라비아숫자 -->
<!-- borderFillIDRef="8" + charPrIDRef="8"  → 하단선만 검정 볼드 제목 -->
```

---

## 워크플로우 2: 기존 문서 편집

레퍼런스 HWPX를 직접 수정할 때 사용한다.

```
# 1. XML 추출
hwpx:extract_hwpx_xml(
    hwpx_path="/mnt/user-data/uploads/document.hwpx",
    extract_dir="/tmp/doc_xml"
)

# 2. /tmp/doc_xml/section0.xml을 bash_tool로 str_replace 편집

# 3. 수정된 XML로 재빌드
hwpx:build_hwpx(
    output_hwpx="/tmp/edited.hwpx",
    header_xml="/tmp/doc_xml/header.xml",
    section_xml="/tmp/doc_xml/section0.xml"
)

# 4. 검증
hwpx:validate_hwpx(hwpx_path="/tmp/edited.hwpx")
```

---

## 워크플로우 3: 읽기/텍스트 추출

```
# 순수 텍스트
hwpx:extract_text_hwpx(hwpx_path="/mnt/user-data/uploads/document.hwpx")

# 테이블 포함
hwpx:extract_text_hwpx(hwpx_path="...", include_tables=true)

# 마크다운 형식
hwpx:extract_text_hwpx(hwpx_path="...", fmt="markdown")
```

---

## 워크플로우 4: 검증

```
hwpx:validate_hwpx(hwpx_path="/tmp/result.hwpx")
```

검증 항목: ZIP 유효성, 필수 파일 존재, mimetype 내용/위치/압축방식, XML well-formedness

---

## 워크플로우 5: 레퍼런스 기반 문서 생성 (양식 HWPX 첨부 시 — 기본 적용)

사용자가 제공한 HWPX 양식을 분석하여 동일한 레이아웃의 새 문서를 생성하는 워크플로우.
**레퍼런스가 존재하면 반드시 이 워크플로우를 기본으로 사용한다.**

### 전체 흐름

```
1. hwpx:analyze_hwpx          → 글꼴/스타일/표 구조 전체 파악
2. hwpx:extract_hwpx_xml      → header.xml + section0.xml 추출
3. [Claude] section0.xml 수정 → 구조 유지, 텍스트/값만 교체
4. hwpx:build_hwpx            → 추출 header.xml + 수정 section0.xml → HWPX 조립
5. hwpx:validate_hwpx         → 구조 무결성 검증
6. hwpx:page_guard_hwpx       → 쪽수 드리프트 검사 (필수 통과 게이트)
7. present_files              → 사용자에게 결과 전달
```

### 상세 MCP 호출 예시

```
# 1. 심층 분석 (구조 청사진 출력 — 스타일 ID, 표 구조, 여백 등 파악)
hwpx:analyze_hwpx(hwpx_path="/mnt/user-data/uploads/reference.hwpx")

# 2. XML 추출
hwpx:extract_hwpx_xml(
    hwpx_path="/mnt/user-data/uploads/reference.hwpx",
    extract_dir="/tmp/ref_xml"
)
# → /tmp/ref_xml/header.xml, /tmp/ref_xml/section0.xml

# 3. [Claude가 bash_tool로 section0.xml 수정]
#    - 동일한 charPrIDRef, paraPrIDRef 사용
#    - 동일한 테이블 구조 (열 수, 열 너비, 행 수, rowSpan/colSpan)
#    - 동일한 borderFillIDRef, cellMargin
#    - 텍스트 노드(<hp:t>)만 교체

# 4. 추출한 header.xml + 수정된 section0.xml로 빌드
hwpx:build_hwpx(
    output_hwpx="/tmp/result.hwpx",
    header_xml="/tmp/ref_xml/header.xml",
    section_xml="/tmp/ref_xml/section0.xml"
)

# 5. 검증
hwpx:validate_hwpx(hwpx_path="/tmp/result.hwpx")

# 6. 쪽수 드리프트 가드 (필수)
hwpx:page_guard_hwpx(
    reference_hwpx="/mnt/user-data/uploads/reference.hwpx",
    output_hwpx="/tmp/result.hwpx"
)

# 7. 출력 디렉토리로 복사 후 전달
# bash: cp /tmp/result.hwpx /mnt/user-data/outputs/result.hwpx
# present_files(["/mnt/user-data/outputs/result.hwpx"])
```

### analyze_hwpx 출력 항목

| 항목 | 설명 |
|------|------|
| 폰트 정의 | hangul/latin 폰트 매핑 |
| borderFill | 테두리 타입/두께 + 배경색 (각 면별 상세) |
| charPr | 글꼴 크기(pt), 폰트명, 색상, 볼드/이탤릭/밑줄/취소선, fontRef |
| paraPr | 정렬, 줄간격, 여백(left/right/prev/next/intent), heading, borderFillIDRef |
| 문서 구조 | 페이지 크기, 여백, 페이지 테두리, 본문폭 |
| 본문 상세 | 모든 문단의 id/paraPr/charPr + 텍스트 내용 |
| 표 상세 | 행×열, 열너비 배열, 셀별 span/margin/borderFill/vertAlign + 내용 |

### 핵심 원칙

- **charPrIDRef/paraPrIDRef를 그대로 사용**: 추출한 header.xml의 스타일 ID를 변경하지 말 것
- **열 너비 합계 = 본문폭**: 분석 결과의 열너비 배열을 그대로 복제
- **rowSpan/colSpan 패턴 유지**: 분석된 셀 병합 구조를 정확히 재현
- **cellMargin 보존**: 분석된 셀 여백 값을 동일하게 적용
- **페이지 증가 금지**: 사용자 명시 승인 없이 결과 쪽수를 늘리지 말 것
- **치환 우선 편집**: 새 문단/표 추가보다 기존 텍스트 노드 치환을 우선할 것

---

## 스크립트/도구 요약

| MCP 도구 | 용도 |
|----------|------|
| `hwpx:analyze_hwpx` | **핵심** — HWPX 심층 분석 (레퍼런스 기반 생성의 청사진) |
| `hwpx:extract_hwpx_xml` | header.xml + section0.xml 추출 |
| `hwpx:build_hwpx` | 템플릿 + XML → HWPX 조립 |
| `hwpx:validate_hwpx` | HWPX 파일 구조 검증 |
| `hwpx:page_guard_hwpx` | 레퍼런스 대비 페이지 드리프트 검사 (필수 게이트) |
| `hwpx:extract_text_hwpx` | HWPX 텍스트 추출 |
| `hwpx:convert_md_to_hwpx` | Markdown → HWPX 직접 변환 (레퍼런스 없을 때) |

## 단위 변환

| 값 | HWPUNIT | 의미 |
|----|---------|------|
| 1pt | 100 | 기본 단위 |
| 10pt | 1000 | 기본 글자크기 |
| 1mm | 283.5 | 밀리미터 |
| 1cm | 2835 | 센티미터 |
| A4 폭 | 59528 | 210mm |
| A4 높이 | 84186 | 297mm |
| 좌우여백 | 8504 | 30mm |
| 본문폭 | 42520 | 150mm (A4-좌우여백) |

## Critical Rules

1. **HWPX만 지원**: `.hwp`(바이너리) 파일은 지원하지 않는다. 사용자가 `.hwp` 파일을 제공하면 **한글 오피스에서 `.hwpx`로 다시 저장**하도록 안내할 것. (파일 → 다른 이름으로 저장 → 파일 형식: HWPX)
2. **secPr 필수**: section0.xml 첫 문단의 첫 run에 반드시 secPr + colPr 포함
3. **mimetype 순서**: HWPX 패키징 시 mimetype은 첫 번째 ZIP 엔트리, ZIP_STORED
4. **네임스페이스 보존**: XML 편집 시 `hp:`, `hs:`, `hh:`, `hc:` 접두사 유지
5. **itemCnt 정합성**: header.xml의 charProperties/paraProperties/borderFills itemCnt가 실제 자식 수와 일치
6. **ID 참조 정합성**: section0.xml의 charPrIDRef/paraPrIDRef가 header.xml 정의와 일치
7. **검증**: 생성 후 반드시 `hwpx:validate_hwpx`로 무결성 확인
8. **레퍼런스**: 상세 XML 구조는 `references/hwpx-format.md` 참조
9. **내장 템플릿 우선**: 레퍼런스 없이 새 문서 생성 시 `hwpx:build_hwpx(template=...)` 사용
10. **빈 줄**: `<hp:t/>` 사용 (self-closing tag)
11. **레퍼런스 우선 강제**: 사용자가 HWPX를 첨부하면 반드시 `hwpx:analyze_hwpx` + `hwpx:extract_hwpx_xml` 기반으로 복원/재작성할 것
12. **쪽수 동일 필수**: 레퍼런스 기반 작업에서는 최종 결과의 쪽수를 레퍼런스와 동일하게 유지할 것
13. **무단 페이지 증가 금지**: 사용자 명시 요청/승인 없이 쪽수 증가를 유발하는 구조 변경 금지
14. **구조 변경 제한**: 사용자 요청이 없는 한 문단/표의 추가·삭제·분할·병합 금지 (치환 중심 편집)
15. **page_guard 필수 통과**: `hwpx:validate_hwpx`와 별개로 `hwpx:page_guard_hwpx`를 반드시 통과해야 완료 처리
16. **파일 경로**: 업로드 파일은 `/mnt/user-data/uploads/`, 출력은 `/mnt/user-data/outputs/`에 저장 후 `present_files()`로 전달
