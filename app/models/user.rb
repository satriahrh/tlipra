class User < ApplicationRecord
    has_many :sleep_records, dependent: :destroy

    has_many :followerships, foreign_key: :follower_id, dependent: :destroy
    has_many :following, through: :followerships, source: :followed

    has_many :reverse_followerships, class_name: "Followership", foreign_key: :followed_id, dependent: :destroy
    has_many :followers, through: :reverse_followerships, source: :follower

    validates :name, presence: true

    def follow!(other_user)
        followership = followerships.find_or_create_by(followed: other_user)
        followership.refollow! if followership.unfollowed?
        followership
    end

    def unfollow!(other_user)
        followership = followerships.find_by(followed: other_user)
        followership&.unfollow!
    end

    def following?(other_user)
        followerships.find_by(followed: other_user, status: "active").present?
    end

    def sleep_clock_in!
        # Check if user already has an active sleep record
        if sleep_records.where(clock_out_at: nil).exists?
            raise BusinessLogicError, "User already has an active sleep record"
        end

        sleep_records.create!(clock_in_at: Time.current)
    end

    def sleep_clock_out!
        # Find the active sleep record
        active_record = sleep_records.where(clock_out_at: nil).last
        if active_record.nil?
            raise BusinessLogicError, "No active sleep record found"
        end

        active_record.update!(clock_out_at: Time.current)
        active_record
    end
end
