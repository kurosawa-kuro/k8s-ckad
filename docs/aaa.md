以下に、**CKAD試験対策用の `kubectl` 実践コマンド集** を整理して提示します。  
セクションごとに分類し、**順に復習しやすい＆コピーしやすい**形式に最適化しました。


# よく使うセット（CKAD模試 or ローカル練習用）
alias k=kubectl
export do="--dry-run=client -o yaml"
alias kn='kubectl config set-context --current --namespace '
alias ke='k explain'
alias kgp='k get po'
alias kaf='k apply -f'

---

## ✅ CKADコマンド チートシート（実践・調査・YAML生成系）

---

### 🔧 基本設定 & 環境確認

```bash
# エイリアス設定（.bashrc / .zshrc などに追加推奨）
alias k=kubectl

# 現在の context に namespace を設定
k config set-context --current --namespace=<namespace>

# config コマンドのヘルプ確認
k config set-context -h

# 使用可能なリソース一覧（Pod関連）
k api-resources | grep po
```

---

### 🔍 リソース構造確認（`kubectl explain`）

```bash
# Deployment の構造（spec 以下）
k explain deploy.spec

# explain コマンドの全体ヘルプ（--recursive 探索）
k explain -h

# volume 関連フィールドの確認
k explain po --recursive | grep volume
k explain deploy --recursive | grep volume

# ConfigMap の再帰的構造
k explain configMap --recursive

# livenessProbe / readinessProbe の確認
k explain po --recursive | grep Probe
```

---

### 📄 YAMLテンプレート生成と適用

```bash
# Pod YAML を生成して編集・適用
k run testpod --image=nginx --dry-run=client -o yaml > pod.yaml
k apply -f pod.yaml

# Deployment YAML の雛形生成
k run testdeploy --image=nginx --dry-run=client -o yaml > testdeploy.yaml

# Service YAML を expose から生成
k expose pod <pod-name> --port=80 --target-port=80 --type=ClusterIP --dry-run=client -o yaml > service.yaml

# --dry-run=client の意味が不明な場合（ヘルプ確認）
k run --help | grep dry
```

---

### 🖥 Pod/Container 状態とデバッグ

```bash
# Pod の状態確認（詳細付き）
k get po -o wide

# 全リソースをネームスペース指定で一覧表示
k get all -n <namespace>

# Pod内に入ってシェル起動（sh または bash）
k exec -it <pod-name> -- /bin/sh
k exec -it <pod-name> -- bash

# busybox Pod で簡易検証（--restart=Never 付き）
k run tmp --rm -it --image=busybox --restart=Never -- sh

# --restart=Never の意味が不明な場合
k run -h | grep busybox
```

---

結論として覚えるべきパターン（丸暗記推奨）
対象	コマンド例
Probe構造	kubectl explain deploy.spec.template.spec.containers.livenessProbe
volume構造	kubectl explain po --recursive
全構造調査	kubectl explain po --recursive

要点まとめ（先に結論） CKAD 本試験の SSH ホストには すでに alias k=kubectl がプリセットされています。したがって 追加設定せずにそのまま k を使うのが最速 です。環境変数 export K=kubectl は $K get pods のように $ を付ける 1 文字と Shift 操作が増えるうえ、試験環境ではうまく評価されない／毎シェルで設定が必要になるケースも報告されています。よって実戦では alias を推奨 します。

1. alias k=kubectl が優位な理由
1.1 プリセットの裏付け
Linux Foundation 公式ドキュメントに「SSH ホストには kubectl と k alias が事前インストール済み」と明記。
1.2 実体験からの推奨
多数の受験記・Tips が「k=kubectl は既にある」「最初の 30 秒で alias を確認せよ」と助言。

2. 環境変数 export K=kubectl を使う場合の落とし穴
呼び出しに $ が要る – $K get pod となり “$” の分だけタイプが増えます。
補完が効かない – bash-completion は環境変数をコマンドとして認識しません。
動作保証なし – Reddit では「export が動かなかった」との報告も。
新シェルで消える – 質問ごとに異なるノードへ SSH するため、毎回 export する手間が発生します。
実際に活用している合格者は少数派で、alias との併用例（do="--dry-run=client -o yaml" など）にとどまっています。

3. 試験開始後 1 分でやること（高速セットアップ）
# ほぼ不要だが念のため確認
alias k        # 既に 'kubectl' が表示されればOK
complete -F __start_kubectl k   # 補完が効かない場合のみ追加入力
# 追加すると便利な変数・alias （5秒でコピペ）
export do="--dry-run=client -o yaml"
alias kn='kubectl config set-context --current --namespace '

do は YAML 雛形生成で頻出。
kn は名前空間切替を短縮。 設定は 1 問目の SSH セッション内で実施し、以後 exit/ssh するたびに再コピペするのが安全です。

4. 補足：練習時の筋肉メモリの作り方
日常から k を使う – .bashrc に alias k=kubectl を入れ、ckad 用クラスタ操作は常に k で。
imperative → declarative – k create deployment nginx --image=nginx $do > dep.yaml の流れを身体で覚える。
省略形リストを暗記 – po,svc,deploy,cm,ing,ns など。
Killer Shell/killercoda で模試 – 本番 UI に近い操作感を事前に体験。

5. まとめ
CKAD 本番は alias k が最速・確実。環境変数は不要かつリスク高。
追加するとしても do など数行に留め、残り時間はタスク攻略に集中しましょう。
疑問が残れば、まず alias k が効くか試す––もし出力が無ければ即時設定。
これで “kubectl 長文タイプ地獄” から解放され、問題解決に専念できます。健闘を祈ります。
