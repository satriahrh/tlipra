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
        followerships.find_by(followed: other_user, status: 'active').present?
    end

    def sleep_clock_in
    end

    def sleep_clock_out
    end
end
