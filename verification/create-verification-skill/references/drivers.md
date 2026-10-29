# 조작 도구와 규칙

검증 스킬을 만들 때 어떤 도구로 앱을 조작할지와, 도구별로 지킬 규칙을 정리한다. agent-browser 관련 내용은 agent-browser 0.23.0에서 직접 확인했다.

## 고르는 순서

1. **저장소에 이미 있는 하네스.** Playwright 설정과 스펙, expectrl PTY 테스트, pytest e2e처럼 저장소가 이미 쓰는 방법이 실제 사용자 경로를 탄다면 그대로 쓴다. 기존 하네스를 버리고 새 도구를 들이지 않는다.
2. **웹 화면과 PWA:** agent-browser.
3. **Electron 앱:** 앱을 `--remote-debugging-port`로 띄우고 `agent-browser --session <이름> connect <포트>`로 붙는다. 자세한 방법은 agent-browser 패키지의 `electron` 스킬에 있다.
4. **Tauri 앱:** macOS의 Tauri는 WKWebView를 써서 CDP 포트가 없다. 웹 프런트엔드를 개발 서버로 따로 띄워 agent-browser로 조작하고, 네이티브 부분은 검증되지 않았다고 스킬에 적는다.
5. **TUI와 CLI:** tmux를 기본으로 쓴다. 대화형 입력이 짧고 정해져 있으면 expect도 된다.
6. **HTTP API:** curl. 응답 본문과 상태 코드를 증거로 남긴다.

## 검증에 쓰지 않는 도구

- **Obscura:** v0.1.1은 localhost, 127.0.0.1, 사설 IP를 막는다. 로컬 개발 서버를 검증할 수 없다.
- **Webwright:** 웹 작업 자동화용 스킬이다. 기능별 피처 맵을 유지하는 검증 체계와 목적이 다르다.
- **Claude in Chrome, 내장 브라우저:** 사용자의 실제 브라우저와 로그인을 함께 쓰므로 실행을 분리할 수 없다. 사용자가 실제 브라우저 확인을 요청할 때만 쓴다.

## agent-browser 규칙

명령 문법은 agent-browser 패키지의 공식 스킬을 따른다. 위치는 `$(npm root -g)/agent-browser/skills/agent-browser/SKILL.md`이다. 아래는 검증 스킬에 꼭 넣어야 하는 규칙이다.

### 실행과 세션

- `npx agent-browser`가 아니라 `agent-browser` 바이너리를 바로 부른다. `npx`는 Node를 거쳐 느리다.
- 실행마다 세션 이름을 새로 만든다. 형식은 `verify-<app>-<run-id>`이다. 세션 이름에는 영문, 숫자, `.`, `_`, `-`만 쓴다.
- 모든 브라우저 명령에 `--session "$S"`를 붙인다. `agent-browser session list`와 `agent-browser upgrade`는 세션과 상관없는 명령이라 예외다. 기본 세션(`default`)이나 다른 이름의 세션은 건드리지 않는다. `close --all`은 쓰지 않는다. 사용자나 다른 에이전트의 세션까지 닫는다.
- 기본은 헤드리스다. `--headed`는 사용자가 실제 창을 보고 싶다고 할 때만 쓴다.
- zsh에서 `AB="agent-browser --session $S"`처럼 변수에 명령을 넣으면 단어로 나뉘지 않아 실패한다. 함수로 감싼다.

### 실행 환경 파일

에이전트의 셸 호출은 매번 새 셸이다. `$$`도 호출마다 달라지고, 앞에서 정의한 변수와 함수도 사라진다. `ab` 함수가 없으면 `ab`는 macOS의 Apache Bench를 실행한다. 그래서 실행을 시작할 때 실행 환경 파일을 한 번 만들고, 이후 모든 셸 호출의 첫 줄에서 그 파일을 `source`한다.

아래 블록은 들여쓰기 없이 그대로 쓴다. heredoc의 끝 줄 `EOF`가 들여쓰기되면 heredoc이 끝나지 않는다.

```bash
# 실행 시작: 한 번만
RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
E="$PWD/.verify-evidence/$RUN_ID"
mkdir -p "$E"
cat > "$E/env.sh" <<EOF
RUN_ID='$RUN_ID'
E='$E'
S='verify-<app>-$RUN_ID'
T='verify-<app>-$RUN_ID'
ab() { agent-browser --session "\$S" "\$@"; }
EOF
echo "$E/env.sh"   # 이 경로를 기억해 둔다
```

```bash
# 이후 모든 셸 호출의 첫 줄
source .verify-evidence/<run-id>/env.sh
```

### 기다리기

- 페이지를 연 뒤 `ab wait --load networkidle`로 기다리고, 그다음 확인할 요소나 글자를 `ab wait --text "<글자>"`나 `ab wait <선택자>`로 기다린다.
- 결과를 확인할 때 고정된 `sleep`을 쓰지 않는다. `sleep`은 영상을 사람이 볼 수 있게 속도를 늦출 때만 쓴다.

### 손잡이

피처 맵의 레시피에는 의미 기반 찾기를 쓴다. 단, agent-browser 0.23.0의 `find role`은 `<button>`과 `role=` 속성을 직접 적은 요소만 찾는다. 링크, 입력란, 검색란, 제목처럼 태그에서 나오는 역할(암묵 역할)은 `snapshot`에는 보여도 `find role`로는 찾지 못한다. 요소마다 아래처럼 쓴다.

| 요소 | 쓸 명령 |
| --- | --- |
| `<button>`, `role="..."`를 직접 적은 요소 | `ab find role button click --name "저장"` |
| 링크, 글자로 찾을 요소 | `ab find text "전체 노트" click --exact` |
| `<label>`로 감싼 입력란 | `ab find label "제목" fill "릴리스 점검표"` |
| `aria-label`만 있는 입력란 | `ab fill 'input[aria-label="노트 검색"]' "분기"` |
| placeholder가 있는 입력란 | `ab find placeholder "검색어" fill "분기"` |
| `data-testid`가 있는 요소 | `ab find testid "submit" click` |

- `find label`은 `<label>` 요소만 본다. `aria-label`은 CSS 속성 선택자로 찾되, 태그를 붙인다(`input[aria-label="..."]`). 대화상자처럼 같은 이름을 가진 다른 요소가 함께 잡히지 않게 하기 위해서다.
- 레시피에 넣는 명령은 4단계 증명에서 모두 한 번씩 실제로 통과해야 한다. 스냅숏에 보인다고 찾기 명령이 통한다고 가정하지 않는다.
- `snapshot -i`가 주는 `@e1` 같은 ref는 그 스냅숏에서만 유효하다. 같은 실행 안에서 새로 찍은 스냅숏에서 얻은 ref만 쓰고, 레시피에 고정값으로 적지 않는다.
- agent-browser를 올린 뒤에는 `find role`이 암묵 역할을 찾는지 다시 확인하고 이 표를 고친다.

### 증거

증거는 모두 `$E`(기본값 `.verify-evidence/<run-id>/`, 저장소가 다른 위치를 정했으면 그곳) 아래에 둔다.

| 무엇을 | 명령 |
| --- | --- |
| 조작 과정 영상 | 조작 전 `ab record start "$E/<기능>.webm"`, 끝나면 `ab record stop` |
| 조작 전후 화면 | `ab screenshot "$E/<기능>-before.png"`, `ab screenshot --annotate "$E/<기능>-after.png"` |
| 화면 구조 | `ab snapshot > "$E/<기능>.aria.txt"` |
| 콘솔과 페이지 오류 | `ab console > "$E/<기능>.console.txt"`, `ab errors > "$E/<기능>.errors.txt"` |
| 네트워크 요청 | `ab network requests --filter "<경로>" > "$E/<기능>.requests.txt"` |

부수 효과는 화면 말고 다른 경로로 한 번 더 확인한다. DB 조회, API GET, 생성된 파일 확인이 그 예다.

### 인증

- 프로젝트에 테스트 계정 명령이 있으면 그것을 쓴다.
- 로그인 상태를 저장해야 하면 `ab state save <파일>`을 쓴다. 이 파일에는 세션 토큰이 평문으로 들어 있다. 증거 폴더가 아니라 임시 폴더(`${TMPDIR}`)에 두고, 정리 단계에서 지우고, 커밋하지 않는다.
- `~/.agent-browser/sessions/`의 저장 상태는 사용자의 것이다. 읽거나 지우지 않는다.

### 정리

agent-browser 0.23.0의 `close`는 브라우저와 데몬을 끝내지만 `~/.agent-browser/<세션>.pid`, `.sock`, `.engine` 파일을 남긴다. 그대로 두면 실행할 때마다 쌓인다. 이 스킬의 `scripts/ab-session-cleanup.sh`로 정리한다. 만든 검증 스킬 안에서는 저장소 루트 기준 경로로 부른다.

```bash
.agents/skills/verify-<app>/scripts/ab-session-cleanup.sh "$S"
```

이 스크립트가 하는 일은 다음과 같다.

- `verify-`로 시작하지 않거나, `/`, `..`, 영문·숫자·`._-` 밖의 글자가 든 세션 이름은 거부한다(종료 코드 2).
- 그 세션에 `close`를 보낸다.
- 데몬 pid가 끝날 때까지 최대 10초 기다린다.
- 그 세션의 `.pid`, `.sock`, `.engine`, `.stream` 파일만 지운다. `.stream`은 정상 `close` 때는 지워지지만 비정상 종료 때 남을 수 있어 함께 지운다.
- 데몬이 끝나지 않으면 파일을 지우지 않고 종료 코드 1로 멈춘다. pid 파일이 없는데 세션이 아직 `session list`에 있어도 같다.

만드는 검증 스킬에는 이 스크립트를 자기 `scripts/`로 복사해 넣는다.

`AGENT_BROWSER_IDLE_TIMEOUT_MS`는 0.23.0에서 확인했을 때 정해진 시간 안에 데몬을 끝내지 않았다. 버려진 세션을 막는 방법으로 이 값에 기대지 않는다.

agent-browser를 올린 뒤(`agent-browser upgrade`)에는 `close` 뒤에 파일이 남는지 다시 확인하고, 이 절을 고친다.

## tmux 규칙

```bash
source .verify-evidence/<run-id>/env.sh      # T, E가 들어 있다
tmux new-session -d -s "$T" -x 120 -y 40      # 명령 없이 셸로 띄운다
tmux send-keys -t "$T" '<실행 명령>' Enter
tmux send-keys -t "$T" e            # 키 하나
tmux send-keys -t "$T" 'hello' Enter # 글자 입력 뒤 Enter
tmux capture-pane -t "$T" -p > "$E/<기능>.screen.txt"
tmux kill-session -t "$T"
```

- `new-session`에 명령을 바로 주면, 금방 끝나는 명령은 끝나는 순간 세션까지 사라져 `capture-pane`이 실패한다. 셸로 띄우고 `send-keys`로 명령을 넣는다.
- 세션 이름은 실행 환경 파일의 `T`를 쓴다. 정리할 때 그 이름의 세션만 끝낸다. `tmux kill-server`는 쓰지 않는다.
- 화면 크기(`-x`, `-y`)를 정해 두어야 캡처가 실행마다 같다.
- 화면이 바뀌기를 기다릴 때는 고정 `sleep` 대신, 기대하는 글자가 `capture-pane` 출력에 나올 때까지 짧게 반복해서 확인한다.
- herdr 안에서 도는 앱은 사용자의 herdr 세션과 분리할 수 있는지 먼저 확인한다. 분리할 수 없으면 실제 herdr 조작은 사용자 확인을 받은 뒤에만 한다고 스킬에 적는다.
