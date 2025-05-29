### CKAD で出題される “Docker 系” タスクの実態

|よく出る作業|具体的な設問例|ひっかけポイント|
|---|---|---|
|**Dockerfile からイメージをビルド**|「~/human-stork/build/Dockerfile を使用して `macque:3.0` という OCI イメージを作成せよ」 ([pass4success.com](https://www.pass4success.com/linux-foundation/discussions/exam-ckad-topic-4-question-16-discussion "Discuss Linux Foundation CKAD Exam Topic 4 Question 16 \| Pass4Success"))|`docker` が無い → `podman` で代替、エイリアスに注意|
|**タグ付け & プライベートレジストリへ Push**|「作成したイメージを `myregistry/me:latest` としてプッシュせよ」 ([Medium](https://medium.com/%40codebob75/passing-ckad-cheatsheet-notes-and-tips-1aa285e6a473?utm_source=chatgpt.com "Passing CKAD: cheatsheet, notes and tips - Medium"))|`docker login` 済かどうか／レジストリ URL の typo|
|**コンテナを実行して動作確認**|「イメージから `bobcontainer` という名前でコンテナを起動し、裏で常駐させよ」 ([Medium](https://medium.com/%40codebob75/passing-ckad-cheatsheet-notes-and-tips-1aa285e6a473?utm_source=chatgpt.com "Passing CKAD: cheatsheet, notes and tips - Medium"))|`-d` を忘れると端末がブロックされる|
|**OCI / tar 形式でエクスポート**|「ビルドしたイメージ (またはコンテナ) を `~/ckad/bobimage_v2.tar` に保存せよ」 ([Medium](https://omishagupta.medium.com/yet-another-ckad-prep-talk-a5fdb965cdee "Yet Another CKAD Prep Talk. A brief about the preparation guide… \| by Omisha Gupta \| Medium"))|`docker save`（イメージ）と `docker export`（コンテナ）の取り違え|
|**最小限の Dockerfile 修正**（稀）|・ベースイメージを Alpine に変える・`USER 1001` を追加して root 以外で実行|レイヤ順序・権限設定を誤るとイメージビルドで失敗|

---

#### 出題頻度と配点イメージ

- **毎回 1 問（4 〜 7 % 程度）** が定番
    
    - 試験ドメイン「Application Design & Build」20 % 中の _Define, build and modify container images_ サブスキルに相当 ([Linux Foundation - Education](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/ "Certified Kubernetes Application Developer (CKAD) - Linux Foundation - Education"))
        
- 難易度は **“手を動かせば 3 分で終わる”** レベル
    
    - Kubernetes リソース操作と違い YAML 編集が不要
        
- **Docker ドキュメントは参照不可**（試験用ブラウザの許可 URL に含まれない）ため、**コマンドは暗記必須**
    

---

#### コマンド暗記ミニチートシート

```bash
# ビルド
docker build -t myimg:1.0 path/to/dir

# タグ付け・プッシュ
docker tag myimg:1.0 myregistry/me:latest
docker push myregistry/me:latest   # 事前に docker login

# 動作確認
docker run -d --name myctr myimg:1.0
docker ps

# tar で保存（イメージ） / export（コンテナ）
docker save myimg:1.0 -o /tmp/myimg.tar
docker export myctr -o /tmp/myctr.tar
```

> **時短テク**：`alias d='docker'` や `export DO='--platform=linux/amd64'` などは `~/.bashrc` に追記可（試験中に 15 秒で仕込めると◎）。

---

#### 典型的な出題パターン

1. **パスが与えられた Dockerfile**
    
    - → _cd_ して _build_ → _tag_ → _push_ → _save/export_。
        
    - Killer.sh でもほぼこの形。
        
2. **Dockerfile を一行だけ修正させる問題**
    
    - 例：`RUN apk add curl` を追加、`EXPOSE 8080` を 9090 に変更。
        
    - `vi Dockerfile` → 修正 → build → push。
        
3. **Podman/Buildah がインストールされている環境**
    
    - `docker` が alias になっていることも多い。コマンドは同一。
        

---

#### 学習・練習のコツ

- **問題文を読み切ってから手を動かす**
    
    - build → run → push → save の順番指定がある場合あり。
        
- **レジストリ URL のコピペ厳禁**（試験環境はマウス選択コピーのみ）。
    
- **OCI = tarball** と覚え、`save` / `export` の違いを体で理解。
    
- K8s リソース問題で時間が足りなくなるので、Docker 問題は **5 分以内に終わらせる** 目標で反復練習。
    

---

##### まとめ

- **頻出度は低いが落とせない 1 問**。
    
- やることは **“ビルド → タグ → 実行 → プッシュ／エクスポート”** のワンパターン。
    
- **Docker の公式サイトは開けない**ので、上記コマンドを丸暗記＋タイピング高速化を。
    
- 余力があれば **multi-stage build** や **non-root USER** の Dockerfile も 1 回書いてみると安心。