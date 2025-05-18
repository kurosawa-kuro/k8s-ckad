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

# CKAD 苦手克服リファレンス

-# CKAD 苦手克服リファレンス

### “覚えやすさ優先”で並べ替えた kcfg

```bash
alias kcfg='kubectl get cm,secret,sa,role,pvc,svc,events -n'
```

#### 並べ替えルール

| ブロック          | リソース           | 覚え方                           | よく見る流れ              |
| ------------- | -------------- | ----------------------------- | ------------------- |
| **① 設定**      | `cm`, `secret` | **C**onfig & **S**ecret       | まず環境変数や証明書を確認       |
| **② 認証/RBAC** | `sa`, `role`   | **S**erviceAccount → **R**ole | 次に誰がアクセスするか確認       |
| **③ ストレージ**   | `pvc`          | **P**ersistent Volume Claim   | Pod Pending の定番チェック |
| **④ 接続口**     | `svc`          | **S**ervice                   | 外部/内部通信が通るか確認       |
| **⑤ 状態ログ**    | `events`       | **E**vents                    | 最後にエラーの事実を掴む        |

頭文字の並び **C-S-S-R-P-S-E** を

> \*\*「**C**hildren **S**ing **S**ongs, **R**abbits **P**lay **S**oft **E**choes」

と語呂合わせしておくと一発で思い出せます。

---

#### 使い方例

```bash
kcfg neptune   # ← Namespace だけ後ろに付ける
```

出力を上から順に眺めれば、
「設定 → 認可 → ストレージ → 通信 → イベント」の典型トラブル診断フローが自然にたどれます。


---

## 1. `kubectl run --command` の流れ

| フェーズ                   | オプション       | 役割                            |
| ---------------------- | ----------- | ----------------------------- |
| **① kubectl 側の解析終了**   | `--`        | これ以降はコンテナ内コマンドとして扱う           |
| **② コンテナ command を明示** | `--command` | `command:` フィールドを自分で定義する宣言    |
| **③ 複数コマンド実行**         | `sh -c "…"` | シェル経由で `cmd1 && cmd2 …` をまとめる |

```bash
# 例: touch してから 1 日スリープする Pod 定義を YAML 生成
kubectl run pod6 \
  --image=busybox:1.31.0 \
  --dry-run=client -o yaml \
  --command -- sh -c "touch /tmp/ready && sleep 1d" \
> pod6.yaml
```

---

## 2. `sh` と `-c`

| キー   | 説明                                 |
| ---- | ---------------------------------- |
| `sh` | POSIX Bourne shell (`/bin/sh`) を起動 |
| `-c` | 直後の文字列を **スクリプト** として実行            |

```bash
sh -c "touch /tmp/ready && sleep 1d"
```

---

## 3. `readinessProbe.exec` の書き方

### 3‑1. 単一バイナリ

```yaml
readinessProbe:
  exec:
    command: ["cat", "/tmp/ready"]
```

### 3‑2. シェル機能が必要な場合

```yaml
readinessProbe:
  exec:
    command:
      - sh
      - -c
      - '[ -f /tmp/ready ] && echo OK || exit 1'
```

---

## 4. 基本 3 パターン早見

| パターン             | 使い所                            | command 例                    |
| ---------------- | ------------------------------ | ---------------------------- |
| **シンプル**         | 単一 bin＋引数                      | `["cat","/tmp/ready"]`       |
| **複数処理 (メイン)**   | Pod `command:`                 | `["sh","-c","cmd1 && cmd2"]` |
| **複数処理 (Probe)** | `readinessProbe.exec.command:` | `["sh","-c","…"]`            |

---

## 5. 直接実行コマンド例

```bash
kubectl run pod7 \
  --image=busybox:1.31.0 \
  --dry-run=client -o yaml \
  --command -- touch /tmp/ready \
> pod7.yaml
# → command: ["touch","/tmp/ready"]
```

---

## 6. リソース監視ワンライナー

| ニーズ           | コマンド                                     | 備考                         |
| ------------- | ---------------------------------------- | -------------------------- |
| 手軽に追従         | `k get po -w`                            | `-w/--watch` で Event ストリーム |
| 画面上書き＆間隔指定    | `watch -n2 k get po`                     | `watch` コマンド前提             |
| どこでも動く汎用 loop | `while true; do k get po; sleep 2; done` | bash さえあれば OK              |

---

## 7. ServiceAccount トークン取得

### 7‑1. 構成を把握

```bash
kubectl describe secret neptune-secret-1 -n neptune
# type: kubernetes.io/service-account-token を確認
# Data === に token / ca.crt / namespace
```

### 7‑2. token 抽出→デコード

```bash
kubectl get secret neptune-secret-1 -n neptune \
  -o jsonpath='{.data.token}' | base64 -d \
  > /opt/course/5/token
```

* `jsonpath` で **Base64 のまま** 値を取得 ⇒ **1 回だけ** `base64 -d`

#### ハマりポイント

| 症状                                                | 原因と対策                               |
| ------------------------------------------------- | ----------------------------------- |
| `template format specified but no template given` | `-o jsonpath` にテンプレを忘れた             |
| `base64: invalid input`                           | 既に JWT になった文字列を再度デコード／jsonpath が空文字 |

---

> これで "単一 vs 複数コマンド"、"Probe の書き方"、"SA トークン抜き"、"リソース監視" の 4 つの弱点をワンページで確認できます。必要に応じて例や図を追加していきましょう 🚀

---

## 8. Pod を別 Namespace へ“移動”する

> **Note:** `metadata.namespace` は *immutable*。`kubectl edit` で書き換えると
> `the namespace from the provided object ... does not match` エラーになる。

### 8‑1. おすすめ手順

```bash
# 元 Pod 定義をダンプ
kubectl get pod webserver-sat-003 -n saturn -o yaml > /tmp/pod.yaml

# namespace: saturn → neptune に置換
sed -i 's/namespace: saturn/namespace: neptune/' /tmp/pod.yaml

# 適用（新ネームスペースに作成）
kubectl apply -f /tmp/pod.yaml

# 旧 Pod を削除（衝突防止）
kubectl delete pod webserver-sat-003 -n saturn
```

### 8‑2. ワンライナー派

```bash
kubectl get pod webserver-sat-003 -n saturn -o yaml \
  | sed 's/namespace: saturn/namespace: neptune/' \
  | kubectl apply -f - && \
kubectl delete pod webserver-sat-003 -n saturn
```

### 8‑3. よくあるエラー & 回避策

| エラー                            | 原因                               | 解決策                              |
| ------------------------------ | -------------------------------- | -------------------------------- |
| `namespace ... does not match` | `kubectl edit` で namespace を直接変更 | *再作成* で対応 (`get` → 編集 → `apply`) |
| `already exists`               | 名前衝突（旧 Pod が残っている）               | 先に `kubectl delete`              |

---

## 9. `--record` フラグとは？

| 観点                                      | 説明                                                                                                                                  |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| 何をする？                                   | **実行した kubectl コマンドを Deployment の履歴 (`rollout history`) に残す**<br>→ PodTemplate に注釈 `kubernetes.io/change-cause: <コマンド文字列>` が自動付与される |
| どのコマンドで使える？                             | `kubectl create / apply / set image / set env / edit …` など、<br>`spec.template` を変更しうるコマンドに付与可能                                      |
| 利点                                      | *あとから誰が何をしたか* が履歴で一目瞭然になる（監査・デバッグ向け）                                                                                                |
| 例                                       | \`\`\`bash                                                                                                                          |
| kubectl set image deploy/api-new-c32 \\ |                                                                                                                                     |
| backend=nginx:9.99-does-not-exist \\    |                                                                                                                                     |
| -n neptune --record                     |                                                                                                                                     |

# history に CHANGE-CAUSE が残る

kubectl rollout history deploy/api-new-c32 -n neptune

```|
| 補足 (K8s v1.18+)| `--record` は非推奨。代わりに<br>`--annotation=kubernetes.io/change-cause="<msg>"` を使うと明示的に残せる |

> **覚え方** : 「`--record` = *コマンドを記録*」。履歴を読む未来の自分のために付けておくと吉。

```
