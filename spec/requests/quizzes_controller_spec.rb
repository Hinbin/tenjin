require 'rails_helper'

RSpec.describe 'using a quiz', type: :request do
  let(:school) { create(:school) }
  let(:student) { create(:student, school: school) }

  before do
    sign_in student
  end

  context 'when navigating to the root quiz path' do
    let(:quiz) { create(:quiz, user: student) }

    it 'displays the latest quiz I have active' do
      quiz
      get quizzes_path
      expect(response).to redirect_to(quiz)
    end

    context 'when I have multiple quizzes' do
      let(:quiz) { create(:quiz, user: student, created_at: DateTime.now - 1.hour) }
      let(:new_quiz) { create(:quiz, user: student) }

      it 'only shows the latest quiz' do
        quiz
        new_quiz
        get quizzes_path
        expect(response).to redirect_to(new_quiz)
      end
    end
  end

  context 'when setting up a quiz' do
    it 'shows the subject select page' do
      get new_quiz_path
      expect(response).to redirect_to dashboard_path
    end

    it 'shows the topic select page for a valid subject' do
      enrollment = create(:enrollment, school: school, user: student)
      get new_quiz_path, params: { subject: enrollment.classroom.subject.name }
      expect(response).to render_template('quizzes/select_topic', 'layouts/application')
    end

    it 'prevents me selecting a topic for a subject I am not allowed to use' do
      create(:enrollment, school: school, user: student)
      different_subject = create(:classroom, school: school)

      get new_quiz_path, params: { subject: different_subject.subject.name }
      expect(response).to redirect_to dashboard_path
    end
  end

  context 'when selecting a subject that does not exist' do
    subject { get new_quiz_path, params: { subject: 'NOSUBJECT' } }

    it { is_expected.to redirect_to(dashboard_path) }

    it 'responds with flash' do
      get new_quiz_path, params: { subject: 'NOSUBJECT' }
      expect(flash[:alert]).to match(/does not exist/)
    end
  end

  describe 'displaying a quiz' do
    context 'when trying to access a quiz' do
      it 'only lets me see a quiz that belongs to me' do
        diff_user = create(:student)
        quiz = create(:quiz, user: diff_user)
        get quiz_path(id: quiz.id)
        expect(flash[:alert]).to match(/Quiz does not belong to you/)
      end

      it 'prevents me from looking at a finished quiz' do
        quiz = create(:quiz, active: false)
        get quiz_path(id: quiz.id)
        expect(flash[:notice]).to match(/The quiz has finished/)
      end
    end

    context 'when displaying a question' do
      let(:question) { create(:question) }
      let(:multiplier) { create(:multiplier) }
      let(:quiz) { create(:quiz, num_questions_asked: 0, user: student) }
      let(:asked_question) { create(:asked_question, question: question, user: student, quiz: quiz) }
      let(:a_subject) { create(:subject) }
      let(:topic) { create(:topic, subject: a_subject) }
      let(:classroom) { create(:classroom, subject: a_subject) }

      before do
        multiplier
      end

      it 'allows me to create a quiz' do
        create(:enrollment, school: school, classroom: classroom, user: student)
        create(:question, topic: topic)
        post quizzes_path params: { quiz: { topic_id: topic, subject: a_subject } }
        follow_redirect!
        expect(response).to render_template('quizzes/_question_top')
      end

      it 'renders a multiple choice quiz question' do
        get quiz_path(id: asked_question.quiz.id)
        expect(response).to render_template('quizzes/question_multiple_choice')
      end

      it 'renders a single word answer question' do
        asked_question = create(:asked_question,
                                question: create(:question, question_type: 'short_answer'),
                                user: student, quiz: quiz)
        get quiz_path(id: asked_question.quiz.id)
        expect(response).to render_template('quizzes/question_short_response')
      end
    end
  end
end
