#!/bin/sh
# node-runtime-updater の e2e テスト。
# 使い捨ての Ubuntu 24.04 (amd64) コンテナ内で root として実行する想定で、
# 実際の GitHub releases からダウンロードしてステージング -> 適用 -> 収束の
# 各シナリオを検証する。/usr/local/bin や /var/lib を実際に書き換えるため、
# 誤って実マシンで実行しないよう NODE_RUNTIME_UPDATER_E2E=1 を要求する。
set -eu

if [ "${NODE_RUNTIME_UPDATER_E2E:-}" != "1" ]; then
  echo "refusing to run: this test mutates /usr/local/bin and /var/lib." >&2
  echo "Set NODE_RUNTIME_UPDATER_E2E=1 inside a throwaway container to run it." >&2
  exit 1
fi
if [ "$(id -u)" != "0" ]; then
  echo "must run as root" >&2
  exit 1
fi

SCRIPTS_DIR=$(cd "$(dirname "$0")/../scripts" && pwd)
APP_DIR=$(cd "$(dirname "$0")/.." && pwd)

# pin は daemonset.yaml から読む (テストと実マニフェストの乖離を防ぐ)
CONTAINERD_VERSION=$(awk '/- name: CONTAINERD_VERSION/{getline; gsub(/[^0-9.]/, ""); print; exit}' "$APP_DIR/daemonset.yaml")
RUNC_VERSION=$(awk '/- name: RUNC_VERSION/{getline; gsub(/[^0-9.]/, ""); print; exit}' "$APP_DIR/daemonset.yaml")
[ -n "$CONTAINERD_VERSION" ] || { echo "failed to parse CONTAINERD_VERSION from daemonset.yaml" >&2; exit 1; }
[ -n "$RUNC_VERSION" ] || { echo "failed to parse RUNC_VERSION from daemonset.yaml" >&2; exit 1; }
echo "testing with containerd=$CONTAINERD_VERSION runc=$RUNC_VERSION"

BIN_DIR=/usr/local/bin
PENDING_DIR=/var/lib/node-runtime-updater/pending
SENTINEL=/var/run/reboot-required

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { pass=$((pass + 1)); echo "ok $pass: $*"; }
assert_file() { [ -f "$1" ] || fail "expected file: $1"; }
assert_absent() { [ ! -e "$1" ] || fail "unexpected file: $1"; }
assert_contains() { echo "$1" | grep -q "$2" || fail "expected output to contain: $2 (got: $1)"; }
assert_pending_empty() {
  leftover=$(find "$PENDING_DIR" -mindepth 1 2>/dev/null || true)
  [ -z "$leftover" ] || fail "expected pending dir to be empty: $leftover"
}

run_updater() { sh "$SCRIPTS_DIR/host-update.sh" "$CONTAINERD_VERSION" "$RUNC_VERSION"; }
run_apply() { sh "$SCRIPTS_DIR/apply.sh"; }

# --- 1. 初回ステージング: 稼働環境には触れず .staged と sentinel だけが作られる ---
out=$(run_updater)
assert_contains "$out" "staged: containerd=$CONTAINERD_VERSION runc=$RUNC_VERSION"
assert_file "$BIN_DIR/containerd.node-runtime-updater.staged"
assert_file "$BIN_DIR/containerd-shim-runc-v2.node-runtime-updater.staged"
assert_file "$BIN_DIR/runc.node-runtime-updater.staged"
assert_absent "$BIN_DIR/containerd"
assert_absent "$BIN_DIR/runc"
assert_file "$PENDING_DIR/containerd.list"
assert_file "$PENDING_DIR/containerd.target"
assert_file "$SENTINEL"
ok "fresh staging leaves binaries untouched and creates sentinel"

# --- 2. 再実行してもダウンロードし直さない (冪等性) ---
out=$(run_updater)
assert_contains "$out" "containerd: none -> $CONTAINERD_VERSION (already staged)"
assert_contains "$out" "runc: none -> $RUNC_VERSION (already staged)"
ok "re-run does not re-download when staging is complete"

# --- 3. 部分適用からの回復: containerd 本体だけ適用され shim が未適用のまま
#        失敗しても、pending list が残っている限り再ステージされる ---
mv "$BIN_DIR/containerd.node-runtime-updater.staged" "$BIN_DIR/containerd"
out=$(run_updater)
assert_contains "$out" "containerd: staging $CONTAINERD_VERSION -> $CONTAINERD_VERSION"
assert_file "$BIN_DIR/containerd.node-runtime-updater.staged"
ok "partial apply is detected and re-staged even when installed version matches pin"

# --- 4. 適用: 全バイナリが配置され pending が消える ---
out=$(run_apply)
assert_contains "$out" "applied staged containerd"
assert_contains "$out" "applied staged runc"
"$BIN_DIR/containerd" --version | grep -q "v$CONTAINERD_VERSION" || fail "installed containerd version mismatch"
"$BIN_DIR/runc" --version | grep -q "runc version $RUNC_VERSION" || fail "installed runc version mismatch"
assert_file "$BIN_DIR/containerd-shim-runc-v2"
assert_pending_empty
if ls "$BIN_DIR"/*.node-runtime-updater.staged >/dev/null 2>&1; then
  fail "staged files must be gone after apply"
fi
ok "apply installs all binaries and clears pending state"

# --- 5. 収束後: 何もせず sentinel も再作成しない ---
rm -f "$SENTINEL"
out=$(run_updater)
assert_contains "$out" "up to date"
assert_absent "$SENTINEL"
ok "converged state is a no-op and does not recreate the sentinel"

# --- 6. pin 巻き戻し: 別バージョン向けの残留ステージングは破棄される ---
echo "9.9.9" > "$PENDING_DIR/runc.target"
echo "$BIN_DIR/runc.node-runtime-updater.staged $BIN_DIR/runc" > "$PENDING_DIR/runc.list"
touch "$BIN_DIR/runc.node-runtime-updater.staged"
out=$(run_updater)
assert_contains "$out" "runc: discarding staging for a different pin"
assert_contains "$out" "up to date"
assert_absent "$BIN_DIR/runc.node-runtime-updater.staged"
assert_pending_empty
assert_absent "$SENTINEL"
ok "staging for a different pin is discarded without touching the sentinel"

# --- 7. pending が無い状態の apply は no-op で成功する ---
run_apply
ok "apply with nothing pending is a successful no-op"

echo "PASS: all $pass scenarios"
