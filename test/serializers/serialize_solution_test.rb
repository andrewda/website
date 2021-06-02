require 'test_helper'

class SerializeSolutionTest < ActiveSupport::TestCase
  test "basic to_hash" do
    solution = create :practice_solution, status: :published, published_at: Time.current - 1.week, completed_at: Time.current
    submission = create :submission, solution: solution
    iteration = create :iteration, submission: submission

    user_track = create :user_track, user: solution.user, track: solution.track
    expected = {
      id: solution.uuid,
      private_url: "https://test.exercism.io/tracks/ruby/exercises/bob",
      public_url: "https://test.exercism.io/tracks/ruby/exercises/bob/solutions/#{solution.user.handle}",
      status: :published,
      mentoring_status: :none,
      has_notifications: false,
      num_views: solution.num_views,
      num_stars: solution.num_stars,
      num_comments: solution.num_comments,
      num_iterations: solution.num_iterations,
      num_loc: solution.num_loc,
      published_at: solution.published_at.iso8601,
      completed_at: solution.completed_at.iso8601,
      updated_at: solution.updated_at.iso8601,
      last_iterated_at: iteration.created_at.iso8601,
      exercise: {
        slug: solution.exercise.slug,
        title: solution.exercise.title,
        icon_url: solution.exercise.icon_url
      },
      track: {
        slug: solution.track.slug,
        title: solution.track.title,
        icon_url: solution.track.icon_url
      }
    }

    assert_equal expected, SerializeSolution.(solution, user_track: user_track)
  end

  test "with no submissions" do
    solution = create :practice_solution, status: :published, published_at: Time.current - 1.week, completed_at: Time.current
    user_track = create :user_track, user: solution.user, track: solution.track

    actual = SerializeSolution.(solution, user_track: user_track)
    assert_nil actual[:last_iterated_at]
  end

  test "with notifications" do
    user = create :user
    track = create :track, :random_slug
    ut_id = create(:user_track, user: user, track: track).id
    exercise = create :practice_exercise, track: track
    solution = create :practice_solution, user: user, exercise: exercise
    discussion = create :mentor_discussion, solution: solution

    # False without user_track
    solution_data = SerializeSolution.(solution)
    refute solution_data[:has_notifications]

    # False with none
    solution_data = SerializeSolution.(solution, user_track: UserTrack.find(ut_id))
    refute solution_data[:has_notifications]

    # Override works
    solution_data = SerializeSolution.(solution, user_track: UserTrack.find(ut_id), has_notifications: true)
    assert solution_data[:has_notifications]

    # True if there is one
    create :mentor_started_discussion_notification, user: user, params: { discussion: discussion }, status: :unread
    solution_data = SerializeSolution.(solution, user_track: UserTrack.find(ut_id))
    assert solution_data[:has_notifications]
  end
end
