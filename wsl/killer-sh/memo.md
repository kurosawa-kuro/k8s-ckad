  1. [kubectl run … --command の流れ](#1-kubectl-run--command-の流れ)  
     1-1. [--command](#1-1---command)  
     1-2. [--](#1-2---)  
     1-3. [sh -c "…"](#1-3-sh--c-)  
  2. [sh と -c の意味](#2-sh-と--c-の意味)  
     2-1. [sh](#2-1-sh)  
     2-2. [-c](#2-2--c)  
  3. [readinessProbe.exec の書き方](#3-readinessprobeexec-の書き方)  
     3-1. [Probe はコンテナ単位](#3-1-probe-はコンテナ単位)  
     3-2. [単一バイナリ実行](#3-2-単一バイナリ実行)  
     3-3. [シェル機能が必要なら](#3-3-シェル機能が必要なら)  
  4. [３つの基本パターン](#4-３つの基本パターン)  
  5. [その他覚え書き](#5-その他覚え書き)  
  6. [直接実行コマンドの例](#6-直接実行コマンドの例)

### 1. `kubectl run … --command` の流れ

* **`--command`**
  「このあと自分でコンテナの `command` フィールドを指定しますよ」という宣言
* **`--`**
  kubectl のオプション解析を終了し、以降はコンテナ内で実行するコマンドとして扱う
* **`sh -c "…"`**
  シェルを呼び出して、複数コマンドをまとめて実行

```bash
kubectl run pod6 \
  --image=busybox:1.31.0 \
  --dry-run=client \
  -o yaml \
  --command -- sh -c "touch /tmp/ready && sleep 1d" \
> pod6.yaml
```

---

### 2. `sh` と `-c` の意味

* **`sh`**
  POSIX 準拠の Bourne shell（`/bin/sh`）を起動
* **`-c`** (“command” の略)
  引数として渡された文字列全体を「スクリプト」としてシェルに実行させる

```shell
sh -c "touch /tmp/ready && sleep 1d"
# → sh に "touch /tmp/ready && sleep 1d" という指示を渡して実行
```

---

### 3. `readinessProbe.exec` の書き方

* **Probe はコンテナ単位**

  ```
  Pod
   └─ spec
       └─ containers[]          ← 複数ある中の 1 つ
           └─ readinessProbe    ← ここに記述
  ```
* **単一バイナリ実行**

  ```yaml
  readinessProbe:
    exec:
      command:
        - cat
        - /tmp/ready
    initialDelaySeconds: 5
    periodSeconds:     10
  ```
* **シェル機能が必要なら**

  ```yaml
  readinessProbe:
    exec:
      command:
        - sh
        - -c
        - '[ -f /tmp/ready ] && echo OK || exit 1'
    initialDelaySeconds: 5
    periodSeconds:     10
  ```

---

### 4. ３つの基本パターン

1. **シンプル**

   * 単一バイナリ＋引数だけ
   * `["cat","/tmp/ready"]`
2. **メイン処理で複数コマンド**

   * Pod の `command` に `["sh","-c","cmd1 && cmd2"]`
3. **Probe でも複雑**

   * `readinessProbe.exec.command: ["sh","-c","…"]`

この３パターンを押さえれば迷いません。

---

### 5. その他覚え書き

* `kubectl explain job.spec.completions`
* `kubectl explain job.spec.parallelism`

---

### 6. 直接実行コマンドの例

* **単一コマンドで Pod を作る**

  ```bash
  kubectl run pod7 \
    --image=busybox:1.31.0 \
    --dry-run=client \
    -o yaml \
    --command -- touch /tmp/ready \
  > pod7.yaml
  ```

  → `command: ["touch","/tmp/ready"]` が出力される

これで「単一処理は直接」「複数処理は `sh -c`」の使い分けがスッキリ整理できるはずです！

while true; do k get po; sleep 2; done