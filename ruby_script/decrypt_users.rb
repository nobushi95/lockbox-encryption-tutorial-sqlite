require "bundler/setup"
require "dotenv"
Dotenv.load(File.expand_path("../.env", __dir__))

require "lockbox"
require "sqlite3"

DB_PATH = File.expand_path("../rails_app/storage/development.sqlite3", __dir__)

def make_box(table:, attribute:)
  key = Lockbox.attribute_key(table: table, attribute: attribute)
  Lockbox.new(key: key, encode: true)
end

name_box  = make_box(table: "users", attribute: "name_ciphertext")
email_box = make_box(table: "users", attribute: "email_ciphertext")
phone_box = make_box(table: "users", attribute: "phone_ciphertext")

db = SQLite3::Database.new(DB_PATH)
db.results_as_hash = true

rows = db.execute("SELECT * FROM users ORDER BY id")

if rows.empty?
  puts "ユーザーが登録されていません"
  exit
end

rows.each do |row|
  puts "ID    : #{row["id"]}"
  puts "名前  : #{name_box.decrypt(row["name_ciphertext"])}"
  puts "メール: #{email_box.decrypt(row["email_ciphertext"])}"
  puts "電話  : #{phone_box.decrypt(row["phone_ciphertext"])}"
  puts "暗号文(name): #{row["name_ciphertext"]}"
  puts "-" * 40
end
