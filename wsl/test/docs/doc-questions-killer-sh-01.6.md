以下が **最新の並び順・重複整理済み** の CKAD 演習ドキュメントです。
各セクションには **問題文＋スタータ YAML** パスを記載しました。
（折りたたみ `<details>` は省き、読みやすさ優先のシンプル構成）

---

# CKAD 模試 Q23 – Q35

| #       | 頻度 | テーマ                                                       |
| ------- | -- | --------------------------------------------------------- |
| **Q23** | ◎  | HPA + LimitRange — *「pulse-api」*                          |
| **Q24** | ◎  | CronJob — *「orbit-backup」*                                |
| **Q25** | ◎  | Probes + Downward API + `kubectl debug` — *「metrics-svc」* |
| **Q26** | ◎  | RBAC + ImagePullSecret — *「deep-reader」*                  |
| **Q27** | ◎  | 詳細 NetworkPolicy — *「venus-mesh」*                         |
| **Q28** | ◯  | Ingress TLS + ExternalName — *「portal-edge」*              |
| **Q29** | ◯  | RollingUpdate〈瞬断ゼロ〉— *「zen-ui」*                           |
| **Q30** | ◯  | Canary Rollout 25 % — *「nova-frontend」*                   |
| **Q31** | △  | Multi-Container (Ambassador) + PDB — *「starlight-api」*    |
| **Q32** | △  | `kubectl auth can-i` 権限制御 — *「galaxy-viewer」*             |

> ◎：ほぼ毎回 ◯：高頻度 △：中頻度 ▽：たまに ▼：ほぼ出ない

---

## Q23 HPA + LimitRange — 「pulse-api」

* スタータ YAML：`Q23-hpa-limitrange/namespace.yaml`
* 目標：replicas 2→5、CPU 70 % トリガの HPA。
  Namespace にデフォルト requests/limits を置く。

---

## Q24 CronJob — 「orbit-backup」

* スタータ YAML：`Q24-cronjob/namespace.yaml`
* 目標：`*/5 * * * *` で `busybox` が `date >> /var/log/orbit.log`。
  実行履歴 keep 成功3 / 失敗1。

---

## Q25 Probes + Downward API + `kubectl debug` — 「metrics-svc」

* スタータ YAML：`Q25-probes-downward-debug/namespace.yaml`
* 目標：Startup + Liveness `/healthz`、Pod 名・Node 名を env へ。
  Ephemeral Container で値を確認。

---

## Q26 RBAC + ImagePullSecret — 「deep-reader」

* スタータ YAML：`Q26-rbac-imagepull/namespace.yaml`
* 目標：SA `deep-sa` に pods/log & exec 権限。
  Docker registry secret を pull 用に紐付け。

---

## Q27 詳細 NetworkPolicy — 「venus-mesh」

* スタータ YAML：`Q27-networkpolicy/namespace.yaml`
* 目標：frontend→api (8080/TCP)、api→db (5432/TCP) のみ許可＋DNS 53。
  それ以外 ingress/egress 全遮断。

---

## Q28 Ingress TLS + ExternalName — 「portal-edge」

* スタータ YAML：`Q28-ingress-tls/namespace.yaml`
* 目標：Host `edge.example.com`，TLS secret `edge-tls`。
  `docs-svc` は ExternalName（ReadTheDocs）。

---

## Q29 RollingUpdate〈瞬断ゼロ〉— 「zen-ui」

* スタータ YAML：`Q29-rollingupdate-zero/namespace.yaml`
* 目標：`maxUnavailable:1` `maxSurge:2` で nginx 1.23→1.26。
  常時 5 Pod 以上 Running を保つ。

---

## Q30 Canary Rollout 25 % — 「nova-frontend」

* スタータ YAML：`Q30-canary-rollout/namespace.yaml`
* 目標：nginx 1.21→1.25 を 25 % で段階デプロイ (`maxSurge:1/Unavailable:0`)。

---

## Q31 Multi-Container Ambassador + PDB — 「starlight-api」

* スタータ YAML：`Q31-ambassador-pdb/namespace.yaml`
* 目標：backend httpd + sidecar curl 2 コンテナ Pod。
  PDB `minAvailable:3`。

---

## Q32 `kubectl auth can-i` — 「galaxy-viewer」

* スタータ YAML：`Q32-auth-can-i/namespace.yaml`
* 目標：SA は get/log/exec だけ YES。
  検証コマンドを `~/auth-lab/verify.sh` へ。

---

## Q34 PriorityClass + NodeAffinity — 「cosmo-worker」

* スタータ YAML：`Q34-priority-affinity/namespace.yaml`
* 目標：Priority 100000。
  preferred zone us-east、fallback us-west。
  かつ `kubernetes.io/arch=amd64` 選択。

---
---

### 備考

* **旧 orion-api 20 % カナリア課題** は Q30 で重複のため削除済み。
* ディレクトリ／ファイル名は “Q番号-テーマ” へリネーム済み。
* まず Q23〜Q32 を制限時間 80 分で回せることを合格ラインとする。

このドキュメントを `README-ckad-practice.md` などに保存してご活用ください。
