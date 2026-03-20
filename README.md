# lockbox 暗号化・復号化 チュートリアル

[lockbox](https://github.com/ankane/lockbox) gem を使ったフィールドレベル暗号化のチュートリアルプロジェクト。

- **rails_app** — フォーム入力データを暗号化して SQLite3 に保存する Rails アプリ
- **ruby_script** — Rails を使わない純粋な Ruby スクリプトで同じ DB から復号化して出力する

両アプリがルートの `.env` に置いたマスターキーを共有することで、アプリをまたいだ暗号化・復号化を実現する。

---

## ディレクトリ構造

```
.
├── .env                          # 開発用環境変数（git 除外）
├── .env.example                  # 環境変数のテンプレート
├── .gitignore
├── .tool-versions                # Ruby 3.3.10
├── rails_app/                    # Rails 7.2 アプリ
│   ├── app/
│   │   ├── controllers/users_controller.rb
│   │   ├── models/user.rb        # has_encrypted でフィールド暗号化
│   │   └── views/users/          # index / new / show
│   ├── db/migrate/               # *_ciphertext カラムのみのスキーマ
│   ├── spec/models/user_spec.rb  # RSpec テスト
│   └── Gemfile
└── ruby_script/
    ├── decrypt_users.rb          # DB から直接読み取り復号化するスクリプト
    └── Gemfile
```

---

## セットアップ

### 前提条件

- Ruby 3.3.10（[asdf](https://asdf-vm.com/) 推奨）

### 1. マスターキーを生成して .env を作成

```bash
ruby -e "require 'lockbox'; puts Lockbox.generate_key"
```

出力されたキーを `.env` に設定する。

```bash
cp .env.example .env
# .env を開いて LOCKBOX_MASTER_KEY に生成したキーを設定
```

### 2. Rails アプリのセットアップ

```bash
cd rails_app
bundle install
bundle exec rails db:create db:migrate
```

### 3. Ruby スクリプトのセットアップ

```bash
cd ../ruby_script
bundle install
```

---

## 動作確認

### Rails アプリの起動とデータ登録

```bash
cd rails_app
bundle exec rails server
```

ブラウザで `http://localhost:3000` を開き、ユーザーを登録する。
show 画面で復号済みの平文と DB に保存された暗号文（`*_ciphertext`）を両方確認できる。

### Ruby スクリプトで復号化

Rails サーバーを起動したまま別ターミナルで実行する。

```bash
cd ruby_script
bundle exec ruby decrypt_users.rb
```

出力例：

```
ID    : 1
名前  : Yamada Taro
メール: taro@example.com
電話  : 090-1234-5678
暗号文(name): sO81qKsn2rjK5DCZBI/IfMYahZhTFdQG2EBOlgkU3juJMfBnPAVX
----------------------------------------
```

### RSpec

```bash
cd rails_app
bundle exec rspec spec/models/user_spec.rb --format documentation
```

### RuboCop

```bash
cd rails_app
bundle exec rubocop
```

---

## 技術的なポイント

### スキーマ設計

lockbox は `フィールド名_ciphertext` カラムにのみ暗号化データを保存する。平文カラムは不要。

```ruby
# db/migrate/*_create_users.rb
create_table :users do |t|
  t.string :name_ciphertext
  t.string :email_ciphertext
  t.string :phone_ciphertext
  t.timestamps
end
```

### モデルの暗号化設定

Rails 7.2 の内蔵 `ActiveRecord::Encryption` との競合を避けるため、lockbox の `has_encrypted` を使用する（`encrypts` は AR Encryption が優先されるため使用不可）。

```ruby
class User < ApplicationRecord
  has_encrypted :name
  has_encrypted :email
  has_encrypted :phone
end
```

### 環境変数の共有

lockbox の Railtie が `LOCKBOX_MASTER_KEY` 環境変数を自動読み込みする。
Rails アプリは `config/application.rb` で、Ruby スクリプトは先頭で dotenv により `.env` をロードする。

```ruby
# Rails: config/application.rb
require "dotenv"
Dotenv.load(File.expand_path("../../.env", __dir__))

# Ruby スクリプト
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))
Lockbox.master_key = ENV.fetch("LOCKBOX_MASTER_KEY")  # Railtie がないため明示設定
```

### スクリプトからの復号化

lockbox 2.x では `has_encrypted :name` 内部のキー派生に **カラム名**（`name_ciphertext`）を使用する。

```ruby
def make_box(table:, attribute:)
  key = Lockbox.attribute_key(table: table, attribute: attribute)
  Lockbox.new(key: key, encode: true)
end

name_box = make_box(table: "users", attribute: "name_ciphertext")
name_box.decrypt(row["name_ciphertext"])  # => "Yamada Taro"
```

---

## 主な依存 gem

| gem | 用途 |
|-----|------|
| [lockbox](https://github.com/ankane/lockbox) | フィールドレベル暗号化（AES-GCM） |
| [dotenv](https://github.com/bkeepers/dotenv) | `.env` ファイルから環境変数をロード |
| [sqlite3](https://github.com/sparklemotion/sqlite3-ruby) | SQLite3 データベースドライバ |
| [rspec-rails](https://github.com/rspec/rspec-rails) | Rails 向け RSpec テストフレームワーク |
| [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase) | Rails 公式スタイルガイドに基づく RuboCop 設定 |
