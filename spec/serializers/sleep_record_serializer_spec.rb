    end
  end

  describe '#duration' do
    context 'when duration is already set' do
      let(:sleep_record) { create(:sleep_record, :completed, user: user, duration: 3600) }

        expect(serializer.id).to be_a(Integer)
      end
    end
  end

  describe '#duration' do
    context 'when duration is already set' do
      let(:sleep_record) { create(:sleep_record, :completed, user: user, duration: 3600) }

      it 'returns the existing duration' do

RSpec.describe SleepRecordSerializer, type: :serializer do
  let(:user) { create(:user) }
  let(:sleep_record) { create(:sleep_record, user: user) }
  let(:serializer) { described_class.new(sleep_record) }

  describe 'attributes' do
    let(:serialized_data) { serializer.as_json }

    it 'includes all required attributes' do
      expect(serialized_data).to include(
        :id,
        :clock_in_at,
        :clock_out_at,
        :duration,
        :created_at
      )
    end

    it 'includes user association when user is present' do
      expect(serialized_data).to include(:user)
      expect(serialized_data[:user]).to be_present
    end
  end

  describe '#duration' do
    context 'when duration is already set' do
      let(:sleep_record) { create(:sleep_record, :completed, user: user, duration: 3600) }

      it 'returns the existing duration' do
        expect(serializer.duration).to eq(3600)
      end
    end

    context 'when duration is not set but clock_out_at is present' do
      let(:clock_in_at) { Time.current }
      let(:clock_out_at) { clock_in_at + 2.hours }
      let(:sleep_record) do
        create(:sleep_record,
               user: user,
               clock_in_at: clock_in_at,
               clock_out_at: clock_out_at,
               duration: nil)
      end

      it 'calculates duration from clock_in_at and clock_out_at' do
        expected_duration = (clock_out_at - clock_in_at).to_i
        expect(serializer.duration).to eq(expected_duration)
      end
    end

    context 'when clock_out_at is not present' do
      let(:sleep_record) { create(:sleep_record, :active, user: user) }

      it 'returns nil' do
        expect(serializer.duration).to be_nil
      end
    end

    context 'when both duration and clock_out_at are nil' do
      let(:sleep_record) { create(:sleep_record, user: user, clock_out_at: nil, duration: nil) }

      it 'returns nil' do
        expect(serializer.duration).to be_nil
      end
    end
  end

  describe 'user association' do
    it 'serializes user with correct attributes' do
      serialized_data = serializer.as_json
      user_data = serialized_data[:user]

      expect(user_data).to include(
        id: user.id,
        name: user.name
      )
    end
  end
end
