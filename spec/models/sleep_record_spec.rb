require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:clock_in_at) }

    context 'when both clock_in_at and clock_out_at are present' do
      it 'validates clock_out_at is after clock_in_at' do
        sleep_record = build(:sleep_record,
          clock_in_at: Time.current,
          clock_out_at: 1.hour.ago
        )

        expect(sleep_record).not_to be_valid
        expect(sleep_record.errors[:clock_out_at]).to include('must be after clock in time')
      end

      it 'is valid when clock_out_at is after clock_in_at' do
        sleep_record = build(:sleep_record,
          clock_in_at: 1.hour.ago,
          clock_out_at: Time.current
        )

        expect(sleep_record).to be_valid
      end
    end
  end

  describe 'duration calculation' do
    context 'when clocking out' do
      it 'calculates duration immediately when setting clock_out_at' do
        sleep_record = create(:sleep_record, clock_in_at: 8.hours.ago)

        # Duration should be nil before setting clock_out_at
        expect(sleep_record.duration).to be_nil

        # Set clock_out_at - duration should be calculated immediately
        sleep_record.clock_out_at = Time.current

        # Duration should be calculated right away, even before saving
        expect(sleep_record.duration).to eq(8 * 3600)
      end

      it 'saves duration to database when saving the record' do
        sleep_record = create(:sleep_record, clock_in_at: 8.hours.ago)
        sleep_record.clock_out_at = Time.current
        sleep_record.save!

        # Duration should be persisted in database
        expect(sleep_record.reload.duration).to eq(8 * 3600)
      end

      it 'does not calculate duration when clock_out_at is nil' do
        sleep_record = create(:sleep_record, clock_in_at: 8.hours.ago)

        # Setting to nil should not calculate duration
        sleep_record.clock_out_at = nil
        expect(sleep_record.duration).to be_nil
      end
    end

    context 'when not clocking out' do
      it 'prevents duration update when clock_out_at is not being changed' do
        sleep_record = create(:sleep_record,
          clock_in_at: 8.hours.ago,
          clock_out_at: Time.current
        )

        original_duration = sleep_record.duration

        # Try to update duration directly - should fail
        sleep_record.duration = 999999
        expect(sleep_record.save).to be_falsey
        expect(sleep_record.errors[:duration]).to include('can only be set when clocking out')

        # Duration should remain unchanged
        expect(sleep_record.reload.duration).to eq(original_duration)
      end
    end
  end
end
