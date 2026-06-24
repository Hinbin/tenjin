# frozen_string_literal: true

# The "who is actually practising" section of Analytics::ClassGapReport. Quizzes-started comes from
# usage_statistics (written live on quiz start); answered-question counts come from the durable
# student_question_statistics rollup — the same source the rest of the report uses — because
# usage_statistics.questions_answered is not populated. Scoped to this subject's topics. Lives in its
# own concern to keep the report class focused; relies on the host's `student_ids` and `topic_ids`.
module Analytics::ClassEngagementSupport
  private

  def engagement
    rows = engagement_per_student
    { students_active: rows.size,
      quizzes_started: rows.sum { |entry| entry[:quizzes_started] },
      questions_answered: rows.sum { |entry| entry[:questions_answered] },
      per_student: rows }
  end

  def engagement_per_student
    return [] if student_ids.empty? || topic_ids.empty?

    answered = answered_by_student
    quizzes = quizzes_by_student
    (answered.keys | quizzes.keys).map { |uid| engagement_entry(uid, answered[uid], quizzes[uid]) }
                                  .sort_by { |entry| -entry[:questions_answered] }
  end

  # Answered-question totals per student from the durable rollup: { user_id => { questions_answered:,
  # last_active_at: } }.
  def answered_by_student
    StudentQuestionStatistic.joins(:question)
                            .where(user_id: student_ids, questions: { topic_id: topic_ids })
                            .group(:user_id)
                            .pluck(:user_id, Arel.sql('SUM(number_asked)'), Arel.sql('MAX(last_asked_at)'))
                            .to_h { |uid, asked, last| [uid, { questions_answered: asked.to_i, last_active_at: last }] }
  end

  # Quizzes-started totals per student from usage_statistics: { user_id => { quizzes_started:,
  # last_active_at: } }.
  def quizzes_by_student
    UsageStatistic.where(user_id: student_ids, topic_id: topic_ids)
                  .group(:user_id)
                  .pluck(:user_id, Arel.sql('SUM(quizzes_started)'), Arel.sql('MAX(date)'))
                  .to_h { |uid, started, date| [uid, { quizzes_started: started.to_i, last_active_at: date }] }
  end

  def engagement_entry(uid, answered, quizzes)
    answered ||= {}
    quizzes ||= {}
    { user_id: uid, name: student_names[uid],
      quizzes_started: quizzes[:quizzes_started].to_i,
      questions_answered: answered[:questions_answered].to_i,
      last_active_at: [answered[:last_active_at], quizzes[:last_active_at]].compact.max }
  end

  def student_names
    @student_names ||= User.where(id: student_ids)
                           .pluck(:id, :forename, :surname)
                           .to_h { |id, forename, surname| [id, "#{forename} #{surname}"] }
  end
end
