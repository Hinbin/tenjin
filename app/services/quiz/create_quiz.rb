# Creates a Quiz session object and initialises it appropriately
class Quiz::CreateQuiz
  def initialize(params)
    @user = params[:user]
    @topic_id = params[:topic]
    @subject_id = params[:subject]
    @topic = Topic.find(@topic_id) unless @topic_id == 'Lucky Dip'
    @quiz = Quiz.new
  end

  def call
    initialise_quiz
    initialise_questions

    @quiz
  end

  def initialise_quiz
    @quiz.user_id = @user.id
    @quiz.time_last_answered = Time.current
    @quiz.streak = 0
    @quiz.answered_correct = 0
    @quiz.num_questions_asked = 0
    @quiz.subject = @topic.subject
    @quiz.active = true
  end

  def initialise_questions
    questions = if @topic_id == 'LD'
                  # We want an even distribution of topics where possible
                  question_array = []

                  # Keep getting random questions, one from each topic until we have at
                  # least 10 questions

                  while question_array.length < 10
                    question_array += Question.find_by_sql(["
                    SELECT
                      DISTINCT ON (questions.topic_id)
                      questions.topic_id, questions.*
                    FROM questions
                    INNER JOIN topics ON questions.topic_id = topics.id
                    LEFT JOIN subjects ON subjects.id = topics.id
                    WHERE subject_id = ?
                    ORDER by questions.topic_id, random()", @subject_id])
                  end

                  # Get maximum of 10 questions only
                  question_array.sample(10)

                else
                  Question.where('topic_id = ?', @topic_id).order(Arel.sql('RANDOM()')).take(10)
                end

    @quiz.questions = questions
  end
end
