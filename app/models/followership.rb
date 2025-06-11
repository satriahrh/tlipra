class Followership < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  enum :status, { active: "active", unfollowed: "unfollowed" }

  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id }

  scope :active, -> { where(status: :active) }
  scope :unfollowed, -> { where(status: :unfollowed) }

  def unfollowed?
    status == "unfollowed"
  end
end
