class User < ApplicationRecord
    has_many :sleep_records, dependent: :destroy

    has_many :followerships, foreign_key: :follower_id, dependent: :destroy
    has_many :following, through: :followerships, source: :followed

    has_many :reverse_followerships, class_name: "Followership", foreign_key: :followed_id, dependent: :destroy
    has_many :followers, through: :reverse_followerships, source: :follower
end
