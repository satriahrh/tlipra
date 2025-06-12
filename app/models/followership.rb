class Followership < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  enum :status, { active: "active", unfollowed: "unfollowed" }

  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_self

  def unfollowed?
    status == "unfollowed"
  end

  def unfollow!
    update!(
      status: "unfollowed",
      unfollowed_at: Time.current
    )
  end

  def refollow!
    update!(
      status: "active",
      unfollowed_at: nil
    )
  end

  private

  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:base, "Cannot follow yourself")
    end
  end
end
