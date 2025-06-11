require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sleep_records).dependent(:destroy) }
    it { should have_many(:followerships).with_foreign_key(:follower_id) }
    it { should have_many(:following).through(:followerships) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe '#follow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    it 'creates a followership' do
      expect { user.follow!(other_user) }.to change(Followership, :count).by(1)
    end

    it 'does not create duplicate followerships' do
      user.follow!(other_user)
      expect { user.follow!(other_user) }.not_to change(Followership, :count)
    end

    it 'updates status to active' do
      user.follow!(other_user)
      expect(Followership.find_by(follower: user, followed: other_user).status).to eq('active')
    end
  end

  describe '#unfollow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before { user.follow!(other_user) }

    it 'marks followership as unfollowed' do
      user.unfollow!(other_user)
      followership = Followership.find_by(follower: user, followed: other_user)
      expect(followership.status).to eq('unfollowed')
    end
  end

  describe '#refollow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before { user.follow!(other_user) }

    it 'keeps the followership but update the status' do
      user.unfollow!(other_user)
      user.follow!(other_user)
      expect(Followership.count).to eq(1)
      expect(user.following?(other_user)).to be_truthy
      user.unfollow!(other_user)
      expect(Followership.count).to eq(1)
      expect(user.following?(other_user)).to be_falsey
    end
  end
end
