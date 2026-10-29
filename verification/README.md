# verification

프로젝트 앱을 사용자처럼 실제로 띄우고 조작해서 동작을 증명하는 검증 스킬 묶음입니다. 스킬 두 개가 짝으로 움직여서 한 폴더에 묶었습니다.

| 스킬 | 하는 일 |
| --- | --- |
| [`create-verification-skill`](create-verification-skill/SKILL.md) | 저장소를 조사해서 그 프로젝트 전용 검증 스킬 `verify-<app>`과 피처 맵을 만들고, 만든 스킬을 한 번 끝까지 실행해 증명합니다. |
| [`maintain-verification-skill`](maintain-verification-skill/SKILL.md) | `verify-<app>`과 피처 맵이 지금 앱과 맞는지 코드 읽기와 실제 조작으로 점검하고, 증명된 수정만 커밋 하나로 묶습니다. |

두 스킬 모두 사람이 직접 불러야 실행됩니다(`disable-model-invocation: true`).

## 필요한 도구

| 도구 | 쓰는 곳 | 확인한 버전 |
| --- | --- | --- |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | 웹 화면과 Electron 조작 | 0.23.0 |
| tmux | TUI와 CLI 조작 | |
| expect | 짧은 대화형 CLI 조작 | |

agent-browser는 패키지 안에 공식 스킬이 들어 있습니다. 명령 문법은 그 스킬을 따르므로 함께 연결해 둡니다.

```bash
npm i -g agent-browser
agent-browser install            # Chrome 내려받기
ln -sfn "$(npm root -g)/agent-browser/skills/agent-browser" ~/.agents/skills/agent-browser
ln -sfn ../../.agents/skills/agent-browser ~/.claude/skills/agent-browser
```

Node 버전을 바꾸면 `npm root -g` 경로가 바뀌어 링크가 끊깁니다. 그때 위 링크를 다시 만듭니다.

## 설치

원본을 `~/.agents/skills`에 두고 Claude Code용 링크를 겁니다.

```bash
git clone git@github.com:demolabskr/my-primary-skillset.git /tmp/my-primary-skillset
for s in create-verification-skill maintain-verification-skill; do
  cp -R /tmp/my-primary-skillset/verification/$s ~/.agents/skills/
  ln -sfn ../../.agents/skills/$s ~/.claude/skills/$s
done
```

## 쓰는 법

1. 검증할 프로젝트 루트에서 `/create-verification-skill`을 부릅니다.
2. 스킬이 `.agents/skills/verify-<app>/`과 `.claude/skills/verify-<app>` 링크를 만들고, `.gitignore`에 `.verify-evidence/`를 추가합니다.
3. 이후 작업에서 "`verify-<app>`으로 검증하고 영상과 스크린샷을 증거로 보여 줘"처럼 요청합니다.
4. 앱이 바뀌면 `/maintain-verification-skill`로 맵을 다시 맞춥니다.

## agent-browser 0.23.0에서 확인한 함정

스킬의 [`references/drivers.md`](create-verification-skill/references/drivers.md)에 반영해 두었습니다.

- `close`는 데몬을 끝내지만 `~/.agent-browser/<세션>.pid/.sock/.engine` 파일을 남깁니다. 스킬에 든 [`scripts/ab-session-cleanup.sh`](create-verification-skill/scripts/ab-session-cleanup.sh)로 그 세션 파일만 지웁니다.
- `find role`은 `<button>`과 `role=` 속성을 직접 적은 요소만 찾습니다. 링크·입력란·제목은 `find text`, `find label`, `find placeholder`, `find testid`, `[aria-label="..."]` 선택자로 찾습니다.
- `AGENT_BROWSER_IDLE_TIMEOUT_MS`를 줘도 정해진 시간 안에 데몬이 끝나지 않았습니다. 정리를 이 값에 맡기지 않습니다.

agent-browser를 올린 뒤에는 이 세 가지를 다시 확인하고 `drivers.md`를 고칩니다.

## 출처와 라이선스

[cursor/plugins](https://github.com/cursor/plugins) 저장소 pstack의 `create-verification-skill`, `maintain-verification-skill`(커밋 `6f6c9e6`)을 한국어로 옮기고, 위 도구와 공용 스킬 경로(`~/.agents/skills`)에 맞게 고쳤습니다. 원본은 MIT 라이선스(Copyright (c) 2026 Lauren Tan)이며, 각 스킬 폴더에 원본 `LICENSE`를 함께 둡니다.
