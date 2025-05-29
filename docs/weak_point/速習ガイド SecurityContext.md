## SecurityContext 速習ガイド（CKAD で “外せない” ポイントだけ）

> **イメージ**  
> 「*_Pod/コンテナに付与する _UNIX 権限のテンプレ__」──  
> UID・GID・capability・SELinux など _ランタイム時の OS 権限_ を宣言的に書くフィールド群です。

---

### 1. スコープは 2 段階

| スコープ                | YAML で書く場所                          | どちらが強い？                   |
| ------------------- | ----------------------------------- | ------------------------- |
| **Pod-level**       | `spec.securityContext`              | 🔧 _デフォルト値_ を配る           |
| **Container-level** | `spec.containers[].securityContext` | 🏋️ **こちらが優先**（Pod 側を上書き） |

> **CKAD では** 1 つの Pod 内で _sidecar だけ root_ にしたい──といったケースが出るので、“上書きルール” を覚えましょう。

---

### 2. 最低限覚える 6 フィールド

| フィールド                       | よく使う値                    | 効果・出題パターン                                          |
| --------------------------- | ------------------------ | -------------------------------------------------- |
| `runAsUser`                 | `1000` など                | プロセス UID を固定。`runAsNonRoot: true` とセットにしがち         |
| `runAsGroup`                | `3000` など                | GID を固定。一般には UID と合わせる                             |
| `runAsNonRoot`              | `true`                   | イメージが UID 0 のままだと **起動失敗**                         |
| `fsGroup`                   | `2000`                   | Pod 内の **書込ボリューム全て** に chgrp する                    |
| `allowPrivilegeEscalation`  | `false`                  | `sudo`, `setuid` で **root 化を抑止**                   |
| `capabilities.add` / `drop` | `NET_ADMIN`, `SYS_TIME`… | 特権を最小化。`NET_ADMIN` を _drop_ して ping 失敗 → デバッグ問題に出る |

#### ざっくり暗記

```
nonroot:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
```

---

### 3. Pod 全体で “非特権” を保証する最短レシピ

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nonroot-pod
spec:
  securityContext:           # ← Pod スコープ
    runAsNonRoot: true
    runAsUser:    1000
    fsGroup:      2000
  containers:
  - name: app
    image: nginx:alpine
    securityContext:         # ← Container スコープ（上書き可）
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
```

_この YAML を 2 分以内に手打ちできれば CKAD の SecurityContext 問題は怖くありません。_

---

### 4. 試験でハマりやすい罠 ＆ デバッグ Tips

|罠|症状|対処|
|---|---|---|
|**UID 1000 で動くアプリ + `runAsNonRoot: true` を忘れる**|Pod が `Error` → イベントに「container has runAsNonRoot and image will run as root」|`runAsNonRoot: true` を追加|
|**root イメージ + `runAsUser: 1000`**|コンテナ起動後にアプリが権限不足でクラッシュ|イメージ側に `USER 1000`、または capability 追加|
|**fsGroup を設定し忘れ RWO Volume で Permission denied**|ログディレクトリ書き込み失敗|`fsGroup` をボリュームの GID に合わせる|
|**capabilities.drop で NET_RAW 落とす → ping 動かず**|Pod 内 `ping` が `Operation not permitted`|`capabilities.add: ["NET_RAW"]` で追加|

> **デバッグコマンド**
> 
> ```bash
> kubectl describe pod nonroot-pod | tail -n 20   # Events を必ず確認
> kubectl exec -it nonroot-pod -- id              # 実際の UID/GID を確認
> ```

---

### 5. PodSecurity Admission (PSA) と絡む位置づけ

1. **PSA ラベル**（`baseline` / `restricted`）がまずフィルタ
    
2. **SecurityContext** で具体的値を上書き  
    _例_: `restricted` では **非特権** が基本 → `privileged: true` は Admission で拒否
    

CKAD では _「PSA ラベルが付いた Namespace で動くように SecurityContext を調整せよ」_ という問題形が増えています。

---

### 6. 30 分スプリントで身につく練習タスク

1. **非特権 Pod** を YAML 手書き → `runAsUser=1000` で nginx 動作確認
    
2. その Pod で **ping を失敗させる**（`capabilities.drop: ["NET_RAW"]`）
    
3. **fsGroup の効果** 確認：emptyDir の `/data` に `touch` できるか観察
    
4. **allowPrivilegeEscalation を false** にして `apt update` が失敗する様子を確認
    

> 👉 _4 タスク × 7 分_ で回すと **SecurityContext 実感値** が跳ね上がります。

---

#### まとめ

- **Pod 全体 vs Container 個別** の優先度だけは絶対に覚える
    
- **runAsNonRoot + allowPrivilegeEscalation + capabilities** が CKAD の 3 本柱
    
- イベント (`kubectl describe`) を読めば大抵のエラー原因は一発で分かる
    

これだけ押さえれば、SecurityContext が絡む CKAD 問題はほぼ取りこぼさないはずです。  
追加で YAML 雛形や alias スニペットが必要なら、いつでもどうぞ！