# CKAD Scheduling Block – Killer Shell Level Practice

> 集中分野: **Pod スケジューリング** (`nodeSelector`, **Tolerations / Taints**, **Node Affinity / Anti‑Affinity**)
> 本試験 (CKAD) で最も頻出する 7 パターンを Killer Shell 風に再構成。各問は **15 分以内** に完了できる難度に調整しています。

---

## 1 | 典型 7 問セット

| #                                   | シナリオ (設問イメージ)                                                                                                                                                                       | 要求タスク                                                                                                                                  | 合格判定コマンド例                                                      |                           |             |           |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------- | ----------- | --------- |
| **1 NodeSelector (超基本)**            | *web‑front* Pod を **node‑1** (label `app=frontend`) のみに配置せよ。                                                                                                                        | 既存 Pod を編集し<br>`spec.nodeSelector.kubernetes.io/hostname=node-1` を追加                                                                   | `kubectl get pod web-front -o jsonpath='{.spec.nodeSelector}'` |                           |             |           |
| **2 単純 Toleration**                 | **node‑2** には `team=ops:NoSchedule` の Taint がある。*log-agent* Pod をそのノードにスケジュールせよ。                                                                                                    | `spec.tolerations` に<br>`key: team, value: ops, effect: NoSchedule` を追加                                                                | \`kubectl describe pod log-agent                               | grep -A1 Tolerations\`    |             |           |
| **3 Required NodeAffinity**         | *mysql* Deployment を **ssd=true** ラベルのノード専用にせよ。                                                                                                                                     | `spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` に<br>`matchExpressions` を追加                  | \`kubectl get deploy mysql -o yaml                             | grep -A4 nodeAffinity\`   |             |           |
| **4 Preferred NodeAffinity (重み付き)** | *cache* Deployment を可能なら **zone=us‑east‑1a** に優先配置 (weight 80)。                                                                                                                     | `preferredDuringSchedulingIgnoredDuringExecution` で `weight: 80` と `matchExpressions` を設定                                              | \`kubectl describe pod -l app=cache                            | grep -i 'node affinity'\` |             |           |
| **5 Inter‑Pod Anti‑Affinity**       | 既に **app=api** Pod が各ノードに 1 つずつ稼働。同じノードに 2 つ置かないようにせよ。                                                                                                                              | `podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution` で<br>`labelSelector: app=api` と `topologyKey: kubernetes.io/hostname` | \`kubectl get pod -l app=api -o wide                           | awk '{print \$1,\$7}'     | sort        | uniq -c\` |
| **6 コンビネーション**                      | ① ノード `gpu=true` を必須 (NodeAffinity)<br>② そのノードは `env=dev:NoSchedule` で汚染 → 許可 (Toleration)<br>③ 同一ノードに `db=postgres` Pod が動いていることを必須 (PodAffinity)<br>→ *analytics* Deployment を作成。 | 3 つの条件をすべて YAML に追加。                                                                                                                   | \`kubectl describe deploy analytics                            | grep -E 'Taints           | Affinity'\` |           |
| **7 Taint デバッグ**                    | *metrics-agent* Pod が Pending。`describe` で `node(s) had taint {key=team, effect=NoSchedule}` と表示。**Deployment を変更せず** 解決せよ。                                                         | 該当ノードから Taint 削除:<br>`kubectl taint nodes <node> team-`                                                                                | `kubectl get pod metrics-agent`                                |                           |             |           |

---

## 2 | 手順 (本番同様のワークフロー)

1. **設問把握 → 120 秒で YAML 追記箇所を決定**
2. **`kubectl explain`** でフィールド確認。
3. **vim/nano 手打ち** (ペースト禁止想定)。階層ズレに注意。
4. **`kubectl apply -f`** → `kubectl get pod -o wide` で配置確認。
5. Pending 時は **`describe` → Events** で直ちに修正。

---

## 3 | 時短ワンライナー

```bash
# 既存 Deploy 編集
k edit deploy myapp    # vim 起動 → 直接修正

# Toleration 付き Skeleton 生成
k run demo --image=alpine --restart=Never \
  --dry-run=client -o yaml > demo.yaml

# 1 行だけ追記して適用
printf '  tolerations:\n  - key: team\n    operator: Equal\n    value: ops\n    effect: NoSchedule\n' >> demo.yaml
k apply -f demo.yaml
```

---

## 4 | ミス防止チェックリスト

* **階層** `template.spec.affinity`? `spec.affinity`? Pod vs Deployment
* **topologyKey** タイポ多数 (正: `kubernetes.io/hostname`)
* **Taint value/effect 大文字小文字** (`NoSchedule`)
* **`podAffinity` vs `podAntiAffinity`** — “anti” 抜け注意

---

⌛ **目安タイピング時間**: Q1 20 s | Q2 35 s | Q3 55 s | Q4‑Q6 ≤ 60‑90 s

この 7 問を 15 分/問 以内で通せれば Scheduling 分野は合格圏です。


| 現場あるある                         | 関連オブジェクト                     | 試験での出題例                              |
| ------------------------------ | ---------------------------- | ------------------------------------ |
| GPU ノードに ML コンテナだけ置きたい         | `nodeSelector`, NodeAffinity | 「accelerator=nvidia ノード限定にせよ」        |
| DB Pod が同じノードで競合 → 別ノードへ分散させたい | Pod Anti-Affinity            | 「`app=db` 同士は同居禁止にせよ」                |
| 運用中にノードをメンテしたい → 一時的に Taint    | Taint / Toleration           | 「`key=maintenance:NoSchedule` を許可せよ」 |

### 「GPU 以外」で **よく使われるノード分類パターン** とミニ練習ネタ

| ラベル例 (`key=value`)                           | 典型ユースケース                   | Node ラベルを付ける主体                             | CKAD-級タスク例                                    |
| -------------------------------------------- | -------------------------- | ------------------------------------------ | --------------------------------------------- |
| `env=prod` / `env=stage`                     | 運用環境を分離（本番 vs 検証）          | クラスタ管理者／NodePool 作成時                       | 「`env=stage` ノードにしか置くな」 (`nodeSelector`)      |
| `disk=ssd` / `disk=hdd`                      | 高 IOPS 必須サービス（DB/Redis）    | 手動 `kubectl label` or GKE/EKS NodePool ラベル | `requiredDuringScheduling…` で `disk In (ssd)` |
| `zone=us-east-1a`                            | AZ 障害ドメインを意識した配置／分散        | クラウド Provider が自動付与                        | 重み 100 で `zone=us-east-1a` を優先 (`preferred`)  |
| `instance-type=spot`                         | スポット/プレエンプティブノード           | GKE ノード自動ラベル                               | spot 専用ワーカーに batch Pod を寄せる                   |
| `kubernetes.io/os=windows`                   | Windows コンテナ分離             | kubelet が自動付与                              | `nodeSelector` で `os=windows` 必須              |
| `arch=arm64` / `kubernetes.io/arch=arm64`    | ARM ノード（Graviton, Tau-T2A） | kubelet 自動                                 | マルチアーチイメージ + `matchExpressions`               |
| `purpose=logging`                            | DaemonSet をログ専用ノードへ        | 手動／Cluster API                             | DaemonSet `tolerations` + `nodeSelector`      |
| `memory=high` (64 GB+)                       | 大量メモリ Job (Spark Driver)   | Cluster Autoscaler / 手動                    | `preferred` weight 50、なければ通常ノード               |
| `gpu=nvidia-tesla-t4`                        | GPU 種類別（T4, A10 etc.）      | Device Plugin Daemon                       | `In (nvidia-tesla-t4)` & `nvidia.com/gpu: 2`  |
| `team=data` (＋ Taint `team=data:NoSchedule`) | チーム専用ノード／マルチテナント隔離         | 管理者                                        | 他チーム Pod は Pending → Toleration 必須            |

---

## ミニ練習 3 問（GPU 以外）

> **制約**: *Killer Shell 難度 — 15 分以内*

| #                    | シナリオ                                                                              | 目標タスク                                                                        | 合格確認                                |                |
| -------------------- | --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------------------------------- | -------------- |
| **A. 高 IOPS DB**     | *postgres* Deployment を **`disk=ssd`** ノード限定                                      | `template.spec.nodeSelector.disk=ssd` 追加                                     | `k get pod -l app=postgres -o wide` |                |
| **B. Windows ノード限定** | *iis-web* Pod を Windows Server ノードのみ                                              | `nodeSelector.kubernetes.io/os=windows` 追加                                   | \`k describe pod iis-web            | grep -i node\` |
| **C. スポット専用 Batch**  | *nightly-job* CronJob が生成する Pod を **`instance-type=spot`** ノード限定、なければ Pending で良い | CronJob → `spec.template.affinity.nodeAffinity.required…` に matchExpressions | \`k get pod -l job-name             | grep spot\`    |

---

### なぜ覚えると得？

1. **クラウド実務**: マネージド NodePool が自動で `topology.kubernetes.io/zone`, `instance-type` を貼る。CKAD で同じキーが出やすい。
2. **障害ドメイン分散**: zone ラベルを使った Anti-Affinity は可用性設計の定番。
3. **コスト最適化**: spot とオンデマンドを選り分ける NodeSelector は FinOps 部署でも常用。

---

#### コードスニペット（覚えやすい形）

```yaml
# Required NodeAffinity for zone us-east-1a
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: topology.kubernetes.io/zone
          operator: In
          values: ["us-east-1a"]
```

```yaml
# Tolerate team=data taint and pin to same nodes
tolerations:
- key: team
  value: data
  effect: NoSchedule
  operator: Equal
nodeSelector:
  team: data
```

---

これで **“GPU 以外のパターンが思いつかない”** 状態は脱出できるはずです。
もっと具体的なケース（例: ARM + GPU 併用、ノードプール名で選択など）が欲しければ教えてください。必要に応じてキャンバスにも追加します！
