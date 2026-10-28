# 노트 만들기

사용자는 브라우저나 CLI에서 제목이 있는 노트를 저장하고, 쓰다 만 초안을 취소하고, 저장된 노트를 다른 화면에서 다시 확인할 수 있다.

## 세부 기능

- `create-open`: 브라우저의 각 진입 경로에서 빈 편집기를 연다.
- `create-save`: 제목과 본문을 저장한다.
- `create-cancel`: 브라우저에서 쓰다 만 초안을 버린다.
- `create-cli`: 터미널에서 같은 형태의 노트를 만든다.

## 들어가는 길 (사용자 관점)

- 브라우저 툴바에서 `새 노트` 버튼을 누른다.
- 브라우저에서 입력란 밖에 포커스가 있을 때 `n`을 누른다.
- 터미널에서 `notes create --title <제목> --body <본문>`을 실행한다.

## agent-browser로 조작하기

전제 조건:

- Notes가 `http://127.0.0.1:4173`에서 정상이다.
- 제목이 `릴리스 점검표`인 노트가 없다.
- 점검(Doctor)이 기대한 URL과 임시 데이터 폴더를 보고한다.
- 실행 환경 파일을 `source`했다(`S`, `E`, `ab`).
- `F="$E/create-note"; mkdir -p "$F"`를 실행했다.

- **녹화 시작.** 첫 조작 전에 `ab record start "$F/create.webm"`을 실행한다.
- **편집기 열기.** `새 노트`를 누른다. `ab find role button click --name "새 노트"`를 실행한다. 이름이 `노트 편집기`인 폼이 나타나고 `제목` 입력란에 포커스가 있다.
- **내용 입력.** 제목과 본문을 입력한다. `ab find label "제목" fill "릴리스 점검표"`와 `ab find label "본문" fill "태그 달고 배포"`를 실행한다. `노트 저장` 버튼이 활성화된다.
- **저장.** `노트 저장`을 누른다. `ab find role button click --name "노트 저장"`과 `ab wait --text "노트를 저장했습니다"`를 실행한다. 상태 메시지가 나타나고 제목이 `릴리스 점검표`로 보인다.
- **저장 유지 확인.** 노트 목록으로 돌아가 노트를 다시 연다. `ab find text "전체 노트" click --exact`와 `ab find text "릴리스 점검표" click --exact`를 실행한다. 편집기에 저장한 두 값이 모두 보인다. `ab record stop`으로 영상을 끝낸다.
- **초안 취소.** 새 노트를 열고 `버릴 노트`를 입력한 뒤 `취소`를 누른다. `ab find role button click --name "새 노트"`, `ab find label "제목" fill "버릴 노트"`, `ab find role button click --name "취소"`를 실행한다. 노트 목록으로 돌아오고 `버릴 노트` 링크가 없다.
- **CLI 진입.** 두 번째 노트를 만든다. `notes create --title "CLI 노트" --body "터미널에서 만듦" --format json > "$F/cli.out" 2> "$F/cli.err"; echo $? > "$F/cli.exit"`를 실행한다. 종료 코드는 `0`이고, stdout에 새 노트 ID와 제목이 있다.
- **증명.** CLI로 만든 노트가 보이도록 목록을 새로 읽고, 저장한 두 노트를 확인한다. `ab find text "전체 노트" click --exact`, `ab reload`, `ab wait --text "CLI 노트"`를 실행한 뒤 `ab snapshot > "$F/list.aria.txt"`와 `ab screenshot --annotate "$F/list.png"`를 실행한다. 두 증거에 `릴리스 점검표`와 `CLI 노트`가 보인다.

## 함정

- 입력란에 포커스가 있을 때 `n`을 누르면 새 편집기가 열리지 않고 글자가 입력된다.
- 제목은 저장할 때 앞뒤 공백이 잘린다. 입력값이 아니라 화면에 나온 제목을 확인한다.
- 저장 상태 메시지만으로는 증명이 되지 않는다. 목록에서 노트를 다시 연다.
- 시드 데이터를 되돌리는 정리 단계에서 `릴리스 점검표`와 `CLI 노트`를 지우되, 그 증거는 남긴다.
