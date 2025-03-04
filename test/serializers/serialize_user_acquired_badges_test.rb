require 'test_helper'

class SerializeUserAcquiredBadgesTest < ActiveSupport::TestCase
  test "basic request" do
    user = create :user
    badge = create :rookie_badge
    acquired_badge = create :user_acquired_badge, revealed: false, badge: badge, user: user

    expected = [
      {
        uuid: acquired_badge.uuid,
        is_revealed: false,
        unlocked_at: acquired_badge.created_at.iso8601,
        name: "Rookie",
        description: "Awarded for submitting an exercise",
        rarity: :common,
        icon_name: :editor,
        num_awardees: 1,
        percentage_awardees: 0.01,
        links: {
          reveal: Exercism::Routes.reveal_api_badge_url(acquired_badge.uuid)
        }
      }
    ]

    assert_equal expected, SerializeUserAcquiredBadges.(user.acquired_badges)
  end
end
