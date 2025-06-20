require 'rails_helper'

RSpec.describe Users::GetSleepRecordsFeedsService do
  let(:user) { create(:user) }
  let(:followed_user) { create(:user) }
  let(:other_user) { create(:user) }

  subject(:service_call) { described_class.new(user, **params).call }

  before do
    user.follow!(followed_user)
  end

  describe '#call' do
    context 'with sleep records from the previous week' do
      let!(:record1) do
        create(:sleep_record, user: followed_user, clock_in_at: 1.week.ago.beginning_of_week + 1.hour, clock_out_at: 1.week.ago.beginning_of_week + 9.hours) # 8h duration
      end
      let!(:record2) do
        create(:sleep_record, user: followed_user, clock_in_at: 1.week.ago.beginning_of_week + 2.hours, clock_out_at: 1.week.ago.beginning_of_week + 8.hours) # 6h duration
      end
      let!(:record_old) do
        create(:sleep_record, user: followed_user, clock_in_at: 2.weeks.ago, clock_out_at: 2.weeks.ago + 8.hours)
      end
      let!(:record_unfollowed) do
        create(:sleep_record, user: other_user, clock_in_at: 1.week.ago.beginning_of_week, clock_out_at: 1.week.ago.beginning_of_week + 8.hours)
      end

      let(:params) { {} }

      it 'returns only the records of the followed user from the previous week' do
        expect(service_call[:records]).to contain_exactly(record1, record2)
      end

      it 'sorts the records by duration in descending order' do
        expect(service_call[:records].first.duration).to be > service_call[:records].last.duration
      end

      it 'returns the correct total count' do
        expect(service_call[:total]).to eq(2)
      end
    end

    context 'with pagination' do
      let(:params) { { page: 2, per_page: 1 } }
      let!(:record1) { create(:sleep_record, user: followed_user, clock_in_at: 1.week.ago.end_of_week - 10.hours, clock_out_at: 1.week.ago.end_of_week - 2.hour) } # 8h
      let!(:record2) { create(:sleep_record, user: followed_user, clock_in_at: 1.week.ago.end_of_week - 12.hours, clock_out_at: 1.week.ago.end_of_week - 6.hour) } # 6h

      it 'returns the correct paginated records' do
        expect(service_call[:records]).to eq([ record2 ])
      end

      it 'returns the correct pagination metadata' do
        expect(service_call[:page]).to eq(2)
        expect(service_call[:per_page]).to eq(1)
        expect(service_call[:total]).to eq(2)
      end
    end

    context 'when providing invalid parameters' do
      it 'raises an error for a non-positive page' do
        params = { page: 0 }
        expect { described_class.new(user, **params).call }.to raise_error(ArgumentError, 'page must be a positive integer')
      end

      it 'raises an error for a non-positive per_page' do
        params = { per_page: -1 }
        expect { described_class.new(user, **params).call }.to raise_error(ArgumentError, 'per_page must be a positive integer')
      end

      it 'raises an error for a non-integer page' do
        # Note: .to_i on a string like 'abc' becomes 0, so this is covered by the positive integer check
        params = { page: 'abc' }
        expect { described_class.new(user, **params).call }.to raise_error(ArgumentError, 'page must be a positive integer')
      end
    end

    context 'when the user follows no one' do
      let(:params) { {} }
      before { user.followerships.destroy_all }

      it 'returns an empty result set' do
        expect(service_call[:records]).to be_empty
        expect(service_call[:total]).to eq(0)
      end
    end

    context 'when followed users have no sleep records' do
      let(:params) { {} }

      it 'returns an empty result set' do
        # Note: No records created in this context
        expect(service_call[:records]).to be_empty
        expect(service_call[:total]).to eq(0)
      end
    end
  end
end
