# my-primary-skillset

직접 쓰는 에이전트 스킬 모음입니다. 폴더 하나가 스킬 하나입니다.

## 외부 스킬

남이 만든 스킬은 여기에 복사해 두지 않고 원본에서 받아 씁니다. 그래야 최신 버전을 쓰고, 라이선스도 원본을 그대로 따릅니다.

| 스킬 | 용도 | 원본 | 라이선스 |
| --- | --- | --- | --- |
| `e2e` | tester-army/e2e로 브라우저·모바일 E2E 테스트 작성·실행·디버깅 | [tester-army/e2e](https://github.com/tester-army/e2e) `skills/e2e` | Apache-2.0 |
| `security-audit` | 코드베이스 보안 감사(정찰·헌팅·검증·보고) | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) `skills/security-audit` | MIT |

### e2e

스킬은 프로젝트에 설치한 `e2e` 패키지 버전과 짝을 맞춰 씁니다. 원본 저장소의 최신 스킬이 설치한 패키지보다 앞설 수 있기 때문입니다.

```bash
# 새 프로젝트: 설정과 함께 .claude/skills/e2e 에 스킬을 설치한다
npx e2e init --skills .claude/skills

# 이미 e2e 를 쓰는 프로젝트: 설치된 패키지 안의 스킬을 복사한다
mkdir -p .claude/skills && cp -r node_modules/e2e/skills/e2e .claude/skills/

# 설치된 버전의 스킬 내용 확인
npx e2e guide
```

### security-audit

[Skills CLI](https://skills.sh)로 받습니다.

```bash
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit          # 프로젝트
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global # 사용자 전체
```

특정 버전으로 고정하려면 원본을 받아 커밋을 지정해 복사합니다. 마지막으로 검증한 커밋은 `c1c8a8c`입니다.

```bash
git clone https://github.com/cloudflare/security-audit-skill /tmp/security-audit-skill
git -C /tmp/security-audit-skill checkout c1c8a8c
mkdir -p .claude/skills && cp -r /tmp/security-audit-skill/skills/security-audit .claude/skills/
```
