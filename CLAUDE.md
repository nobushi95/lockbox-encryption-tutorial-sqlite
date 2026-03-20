# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

lockbox gem を使ったフィールドレベル暗号化（AES-GCM）のチュートリアル実装。Rails アプリと、Rails を使わないスタンドアロン Ruby スクリプトの2つのコンポーネントがある。

## 環境構築

Ruby バージョンは `.tool-versions` で `3.3.10` を指定。

マスターキーの設定（rails_app と ruby_script で共有）:
```bash
# ルートの .env に設定（.env.example を参照）
LOCKBOX_MASTER_KEY=<64文字の16進数>
# キー生成コマンド:
ruby -e "require 'lockbox'; puts Lockbox.generate_key"
```

### Rails アプリ

```bash
cd rails_app
bundle install
bundle exec rails db:create db:migrate
bundle exec rails server
```

### Ruby スクリプト

```bash
cd ruby_script
bundle install
bundle exec ruby decrypt_users.rb
```

## よく使うコマンド

### テスト（rails_app ディレクトリから）

```bash
# 全テスト実行
bundle exec rspec

# 特定のファイルのみ
bundle exec rspec spec/models/user_spec.rb

# ドキュメント形式で出力
bundle exec rspec spec/models/user_spec.rb --format documentation
```

### Lint / セキュリティスキャン

```bash
cd rails_app

# RuboCop
bundle exec rubocop
bundle exec rubocop -a  # 自動修正

# Brakeman（セキュリティ脆弱性スキャン）
bundle exec brakeman --no-pager
```

### DB 操作

```bash
cd rails_app
bundle exec rails db:migrate
bundle exec rails db:reset  # drop + create + migrate
```

## アーキテクチャ

### 暗号化の仕組み

- DBスキーマには `name_ciphertext`、`email_ciphertext`、`phone_ciphertext` のみ存在（平文カラムなし）
- `has_encrypted :name` のように宣言するだけで、`user.name` への読み書きが自動的に暗号化・復号化される
- マスターキー（`LOCKBOX_MASTER_KEY`）はルートの `.env` で一元管理し、`rails_app/config/application.rb` の dotenv で読み込む

### 2つのコンポーネント

| コンポーネント | 場所 | 役割 |
|---|---|---|
| Rails アプリ | `rails_app/` | フォームからの登録・一覧・詳細表示 |
| Ruby スクリプト | `ruby_script/` | Rails なしで SQLite3 から直接読取・復号化 |

### ruby_script の復号化ロジック

Rails を使わず lockbox gem 単体で復号化する場合、属性ごとのキーを `Lockbox.attribute_key` で導出し、`Lockbox.new(key: attribute_key).decrypt(ciphertext)` で復号化する。

## CI（GitHub Actions）

`rails_app/.github/workflows/ci.yml` で以下を自動実行:
- `brakeman` — セキュリティスキャン
- `rubocop` — コードスタイル
- `importmap audit` — JS 依存性スキャン
