class Homework::UpdateHomeworkProgress
  def initialize(quiz)
    @quiz = quiz
    @homework_progresses = HomeworkProgress.includes(:homework).where(user: @quiz.user)
  end

  def call
    completed_homework = false
    @homework_progresses.each do |h|
      check_percentage_correct(h)
    end
    return OpenStruct.new(success?: true, completed?: completed_homework, errors: nil)
  end

  def check_percentage_correct(h)
    return unless @quiz.topic == h.homework.topic

    check_progress_percentage(@quiz.answered_correct.to_f / @quiz.num_questions_asked.to_f, h)
  end

  def check_progress_percentage(percentage, h)
    percentage *= 100
    h.progress = percentage if percentage > h.progress
    h.completed = true if h.progress >= h.homework.required && h.completed == false
    h.save if h.changed?
  end

end
