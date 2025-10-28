require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
  end

  describe 'ransackable' do
    it 'defines ransackable_associations' do
      expect(User.ransackable_associations).to eq([])
    end

    it 'defines ransackable_attributes' do
      expect(User.ransackable_attributes).to include('email', 'created_at', 'updated_at')
    end
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end
  end
end