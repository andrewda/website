module Git
  class SyncPracticeExercise < Sync
    include Mandate

    def initialize(exercise, force_sync: false)
      super(exercise.track, exercise.synced_to_git_sha)
      @exercise = exercise
      @force_sync = force_sync
    end

    def call
      return exercise.update_columns(synced_to_git_sha: head_git_exercise.synced_git_sha) unless force_sync || exercise_needs_updating?

      exercise.update!(
        slug: exercise_config[:slug],
        title: exercise_config[:name].presence,
        status: exercise_config[:status] || :active,
        difficulty: exercise_config[:difficulty],
        icon_name: head_git_exercise.icon_name,
        blurb: head_git_exercise.blurb,
        position: exercise_position,
        git_sha: head_git_exercise.synced_git_sha,
        synced_to_git_sha: head_git_exercise.synced_git_sha,
        prerequisites: find_concepts(exercise_config[:prerequisites]),
        practiced_concepts: find_concepts(exercise_config[:practices]),
        has_test_runner: head_git_exercise.has_test_runner?
      )

      SyncExerciseAuthors.(exercise)
      SyncExerciseContributors.(exercise)
      SiteUpdates::ProcessNewExerciseUpdate.(exercise)
    end

    private
    attr_reader :exercise, :force_sync

    def exercise_needs_updating?
      track_config_exercise_modified? || exercise_config_modified? || exercise_files_modified?
    end

    def track_config_exercise_modified?
      return false unless track_config_modified?

      exercise_position != exercise.position ||
        exercise_config[:slug] != exercise.slug ||
        exercise_config[:name] != exercise.title ||
        (exercise_config[:status] || :active) != exercise.status ||
        exercise_config[:difficulty] != exercise.difficulty ||
        exercise_config[:prerequisites].to_a.sort != exercise.prerequisites.map(&:slug).sort ||
        exercise_config[:practices].to_a.sort != exercise.practiced_concepts.map(&:slug).sort
    end

    def exercise_config_modified?
      return false unless filepath_in_diff?(head_git_exercise.config_absolute_filepath)

      head_git_exercise.blurb != exercise.blurb ||
        head_git_exercise.icon_name != exercise.icon_name ||
        head_git_exercise.authors.to_a.sort != exercise.authors.map(&:github_username).sort ||
        head_git_exercise.contributors.to_a.sort != exercise.contributors.map(&:github_username).sort ||
        head_git_exercise.has_test_runner? != exercise.has_test_runner?
    end

    def exercise_files_modified?
      head_git_exercise.tooling_absolute_filepaths.any? { |filepath| filepath_in_diff?(filepath) }
    end

    def find_concepts(slugs)
      slugs.to_a.map do |slug|
        concept_config = head_git_track.concepts.find { |e| e[:slug] == slug }
        ::Concept.find_by!(uuid: concept_config[:uuid])
      rescue StandardError
        # TODO: (Optional) Remove this rescue when configlet works
      end.compact
    end

    memoize
    def exercise_position
      # The hello-world exercise is always the first exercise
      return 0 if exercise_config[:slug] == 'hello-world'

      # Offset by 1 to account for the hello-world exercise always
      # being the very first exercise and offset by the number of concept
      # exercises to position practice exercises after concept exercises
      exercise_index + 1 + head_git_track.concept_exercises.length
    end

    memoize
    def exercise_index
      head_git_track.practice_exercises.find_index { |e| e[:uuid] == exercise.uuid }
    end

    memoize
    def exercise_config
      head_git_track.practice_exercises[exercise_index]
    end

    memoize
    def head_git_exercise
      Git::Exercise.new(exercise_config[:slug], exercise.git_type, git_repo.head_sha, repo: git_repo)
    end
  end
end
