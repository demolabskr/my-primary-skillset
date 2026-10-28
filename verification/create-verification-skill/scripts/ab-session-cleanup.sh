#!/usr/bin/env bash
# agent-browser 검증 세션 하나를 닫고, 그 세션이 남긴 데몬 파일만 지운다.
# agent-browser 0.23.0의 close는 데몬을 끝내지만 <세션>.pid/.sock/.engine 파일을 남긴다.
# .stream은 세션이 열려 있는 동안 생기고 정상 close 때 지워진다. 비정상 종료 때 남을 수 있어 함께 지운다.
# 사용법: ab-session-cleanup.sh <세션 이름>
# 종료 코드: 0 정리함, 1 데몬이 아직 살아 있음, 2 잘못된 인자
set -u
if [ $# -ne 1 ]; then
  echo "사용법: ab-session-cleanup.sh <세션 이름>" >&2
  exit 2
fi
S="$1"
case "$S" in
  */* | *..*) echo "세션 이름에 / 나 .. 를 쓸 수 없다: $S" >&2; exit 2 ;;
esac
if ! [[ "$S" =~ ^verify-[A-Za-z0-9._-]+$ ]]; then
  echo "verify- 로 시작하고 영문·숫자·._- 만 쓴 세션만 정리한다: $S" >&2
  exit 2
fi
D="${VERIFY_AB_STATE_DIR:-$HOME/.agent-browser}"

agent-browser --session "$S" close >/dev/null 2>&1 || true

pid=""
[ -f "$D/$S.pid" ] && pid=$(cat "$D/$S.pid")
if [ -n "$pid" ]; then
  for _ in $(seq 1 20); do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.5
  done
  if kill -0 "$pid" 2>/dev/null; then
    echo "데몬이 10초 뒤에도 살아 있다(pid $pid). 파일을 지우지 않고 멈춘다." >&2
    exit 1
  fi
elif [ -S "$D/$S.sock" ] && agent-browser session list 2>/dev/null | grep -qx "  $S"; then
  echo "pid 파일은 없는데 세션이 아직 목록에 있다: $S. 파일을 지우지 않고 멈춘다." >&2
  exit 1
fi

rm -f "$D/$S.pid" "$D/$S.sock" "$D/$S.engine" "$D/$S.stream"
echo "정리함: $S"
