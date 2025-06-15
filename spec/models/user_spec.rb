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

  describe '#follow!' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    it 'creates a followership when not following' do
      expect { user.follow!(other_user) }.to change(Followership, :count).by(1)
    end

    it 'refollows when previously unfollowed' do
      followership = user.followerships.create!(followed: other_user, status: 'unfollowed')
      expect { user.follow!(other_user) }.not_to change(Followership, :count)
      expect(followership.reload.status).to eq('active')
    end
  end

  describe '#unfollow!' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before { user.follow!(other_user) }

    it 'marks followership as unfollowed' do
      user.unfollow!(other_user)
      followership = Followership.find_by(follower: user, followed: other_user)
      expect(followership.status).to eq('unfollowed')
    end

    it 'raises error when not following' do
      another_user = create(:user)
      expect { user.unfollow!(another_user) }.to raise_error(BusinessLogicError, "Not following this user")
    end

    it 'raises error when already unfollowed' do
      user.unfollow!(other_user)
      expect { user.unfollow!(other_user) }.to raise_error(BusinessLogicError, "Already unfollowed this user")
    end
  end

  describe '#following?' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    it 'returns true when actively following' do
      user.follow!(other_user)
      expect(user.following?(other_user)).to be_truthy
    end

    it 'returns false when not following' do
      expect(user.following?(other_user)).to be_falsey
    end

    it 'returns false when unfollowed' do
      user.follow!(other_user)
      user.unfollow!(other_user)
      expect(user.following?(other_user)).to be_falsey
    end
  end

  describe '#sleep_clock_in!' do
    let(:user) { create(:user) }

    it 'creates a sleep record' do
      expect { user.sleep_clock_in! }.to change(SleepRecord, :count).by(1)
    end

    it 'raises an error if user already has an active sleep record' do
      user.sleep_clock_in!
      expect { user.sleep_clock_in! }.to raise_error(BusinessLogicError, "User already has an active sleep record")
    end
  end

  describe '#sleep_clock_out!' do
    let(:user) { create(:user) }

    it 'raises an error if user has no active sleep record' do
      expect { user.sleep_clock_out! }.to raise_error(BusinessLogicError, "No active sleep record found")
    end

    it 'updates the sleep record' do
      user.sleep_clock_in!
      expect { user.sleep_clock_out! }.to change { user.sleep_records.last.clock_out_at }.from(nil)
    end
  end
end
