require "rails_helper"

RSpec.describe User, type: :model do
  before(:all) { Lockbox.master_key = ENV.fetch("LOCKBOX_MASTER_KEY", "0" * 64) }

  let(:user) { User.create!(name: "山田太郎", email: "taro@example.com", phone: "090-1234-5678") }

  it "平文で参照できる" do
    expect(user.name).to eq("山田太郎")
    expect(user.email).to eq("taro@example.com")
    expect(user.phone).to eq("090-1234-5678")
  end

  it "name_ciphertextに平文が保存されていない" do
    expect(user.name_ciphertext).not_to eq("山田太郎")
    expect(user.name_ciphertext).not_to be_nil
  end

  it "DB再取得後も復号化できる" do
    found = User.find(user.id)
    expect(found.name).to eq("山田太郎")
    expect(found.email).to eq("taro@example.com")
    expect(found.phone).to eq("090-1234-5678")
  end

  it "name/email/phone はバリデーション必須" do
    invalid = User.new
    expect(invalid).not_to be_valid
    expect(invalid.errors[:name]).to be_present
    expect(invalid.errors[:email]).to be_present
    expect(invalid.errors[:phone]).to be_present
  end
end
