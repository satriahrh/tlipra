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

  describe 'clock_in_at immutability' do
    context 'when trying to update clock_in_at after creation' do
      let(:sleep_record) { create(:sleep_record, clock_in_at: 8.hours.ago) }

      it 'prevents clock_in_at from being changed' do
        original_clock_in_at = sleep_record.clock_in_at

        sleep_record.clock_in_at = 1.hour.ago

        expect(sleep_record.save).to be_falsey
        expect(sleep_record.errors[:clock_in_at]).to include('cannot be changed after creation')
      end

      it 'prevents clock_in_at from being changed via update!' do
        expect {
          sleep_record.update!(clock_in_at: 1.hour.ago)
        }.to raise_error(ActiveRecord::RecordNotSaved)

        expect(sleep_record.errors[:clock_in_at]).to include('cannot be changed after creation')
      end

      it 'prevents clock_in_at from being changed via update' do
        result = sleep_record.update(clock_in_at: 1.hour.ago)

        expect(result).to be_falsey
        expect(sleep_record.errors[:clock_in_at]).to include('cannot be changed after creation')
      end

      it 'allows other attributes to be updated' do
        sleep_record.clock_out_at = Time.current

        expect(sleep_record.save).to be_truthy
        expect(sleep_record.reload.clock_out_at).to be_present
      end

      it 'allows clock_in_at to be set during creation' do
        new_sleep_record = build(:sleep_record, clock_in_at: 2.hours.ago)

        expect(new_sleep_record.save).to be_truthy
        expect(new_sleep_record.clock_in_at.to_i).to eq(2.hours.ago.to_i)
      end

      it 'allows clock_in_at to be set during creation with different times' do
        new_sleep_record = build(:sleep_record, clock_in_at: 3.hours.ago)

        expect(new_sleep_record.save).to be_truthy
        expect(new_sleep_record.clock_in_at.to_i).to eq(3.hours.ago.to_i)
      end
    end

    context 'when clock_in_at is not being changed' do
      let(:sleep_record) { create(:sleep_record, clock_in_at: 8.hours.ago) }

      it 'allows updates to other attributes' do
        sleep_record.clock_out_at = Time.current

        expect(sleep_record.save).to be_truthy
        expect(sleep_record.reload.clock_out_at).to be_present
      end

      it 'allows updates when clock_in_at is set to the same value' do
        original_clock_in_at = sleep_record.clock_in_at
        sleep_record.clock_in_at = original_clock_in_at
        sleep_record.clock_out_at = Time.current

        expect(sleep_record.save).to be_truthy
      end
    end

    context 'when clock_in_at is nil during creation' do
      it 'allows setting clock_in_at during creation' do
        sleep_record = build(:sleep_record, clock_in_at: nil)
        sleep_record.clock_in_at = Time.current

        expect(sleep_record.save).to be_truthy
        expect(sleep_record.clock_in_at).to be_present
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
