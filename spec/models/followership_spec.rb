require 'rails_helper'

RSpec.describe Followership, type: :model do
  describe 'associations' do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:follower_id) }
    it { should validate_presence_of(:followed_id) }

    it 'validates uniqueness of follower_id and followed_id combination' do
      followership = create(:followership)
      duplicate = build(:followership,
                       follower: followership.follower,
                       followed: followership.followed)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:follower_id]).to include('has already been taken')
    end
  end

  describe 'custom validations' do
    describe '#cannot_follow_self' do
      let(:user) { create(:user) }

      it 'is invalid when follower and followed are the same' do
        followership = build(:followership, follower: user, followed: user)
        expect(followership).not_to be_valid
        expect(followership.errors[:base]).to include('Cannot follow yourself')
      end

      it 'is valid when follower and followed are different' do
        other_user = create(:user)
        followership = build(:followership, follower: user, followed: other_user)
        expect(followership).to be_valid
      end
    end
  end

  describe '#unfollow!' do
    let(:followership) { create(:followership, status: 'active') }

    it 'changes status to unfollowed' do
      followership.unfollow!
      expect(followership.status).to eq('unfollowed')
    end

    it 'sets unfollowed_at timestamp' do
      expect { followership.unfollow! }.to change { followership.unfollowed_at }
        .from(nil).to(be_present)
    end

    it 'updates the record' do
      expect { followership.unfollow! }.to change { followership.updated_at }
    end
  end

  describe '#refollow!' do
    let(:followership) { create(:followership, :unfollowed) }

    it 'changes status to active' do
      followership.refollow!
      expect(followership.status).to eq('active')
    end

    it 'clears unfollowed_at timestamp' do
      expect { followership.refollow! }.to change { followership.unfollowed_at}
        .from(be_present).to(be_nil)
    end

    it 'updates the record' do
      expect { followership.refollow! }.to change { followership.updated_at }
    end
  end

  describe 'enum methods' do
    let(:followership) { create(:followership) }

    it 'responds to active?' do
      expect(followership).to respond_to(:active?)
    end

    it 'responds to unfollowed?' do
      expect(followership).to respond_to(:unfollowed?)
    end

    it 'returns true for active? when status is active' do
      followership.update!(status: 'active')
      expect(followership.active?).to be true
    end

    it 'returns true for unfollowed? when status is unfollowed' do
      followership.update!(status: 'unfollowed')
      expect(followership.unfollowed?).to be true
    end

    describe 'defines scope' do
      let!(:active_followership) { create(:followership, status: 'active') }
      let!(:unfollowed_followership) { create(:followership, :unfollowed) }

      describe '.active' do
        it 'returns only active followerships' do
          expect(Followership.active).to include(active_followership)
          expect(Followership.active).not_to include(unfollowed_followership)
        end
      end

      describe '.unfollowed' do
        it 'returns only unfollowed followerships' do
          expect(Followership.unfollowed).to include(unfollowed_followership)
          expect(Followership.unfollowed).not_to include(active_followership)
        end
      end
    end
  end
end
