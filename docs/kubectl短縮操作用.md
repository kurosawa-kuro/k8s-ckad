## ✅ CKAD模試・試験直前セットアップ：最小＆最強構成

---

### 🔧 ① 基本エイリアスの登録（kubectl短縮操作用）

```bash
alias k=kubectl                               # kubectl の省略形
alias ke='k explain'                          # リソース構造の確認に便利
alias kgp='k get po'                          # Pod一覧表示のショートカット
alias kaf='k apply -f'                        # YAML適用のショートカット

k config set-context -h | grep name           # --current と --namespace の構文確認
alias kn='kubectl config set-context --current --namespace '  # namespace切替コマンド

alias

k run -h | grep dry                           # --dry-run=client の使い方確認
export do="--dry-run=client -o yaml"          # よく使う構文を変数化

echo $do                                      # 変数の確認（任意）
```
