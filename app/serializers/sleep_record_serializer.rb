class SleepRecordSerializer < ActiveModel::Serializer
  attributes :id, :clock_in_at, :clock_out_at, :duration, :created_at
  belongs_to :user, if: -> { object.user.present? }

  def duration
    object.try(:duration) || (object.clock_out_at && object.clock_in_at ? (object.clock_out_at - object.clock_in_at).to_i : nil)
  end
end
