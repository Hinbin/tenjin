# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'using a quiz', :default_creates, type: :request do
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
      let(:quiz) { create(:quiz, user: student, created_at: Time.now - 1.hour) }
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
      expect(response).to have_http_status(:success)
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
        quiz = create(:new_quiz, user: diff_user, question_order: [question.id])
        get quiz_path(id: quiz.id)
        expect(flash[:alert]).to match(/Quiz does not belong to you/)
      end

      it 'shows the results screen for a finished quiz' do
        quiz = create(:new_quiz, user: student, active: false, question_order: [question.id])
        get quiz_path(id: quiz.id)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Points earned')
      end
    end

    context 'when displaying a question' do
      let(:multiplier) { create(:multiplier) }
      let(:quiz) { create(:new_quiz, user: student, question_order: [question.id]) }
      let(:classroom) { create(:classroom, subject: subject) }

      before do
        multiplier
      end

      it 'allows me to create a quiz' do
        create(:enrollment, school: school, classroom: classroom, user: student)
        create(:question, topic: topic)
        post quizzes_path params: { quiz: { topic_id: topic, subject: subject } }
        follow_redirect!
        expect(response).to have_http_status(:success)
      end

      it 'renders a multiple choice quiz question' do
        get quiz_path(id: quiz.id)
        expect(response).to have_http_status(:success)
      end

      it 'renders a single word answer question' do
        question = create(:question, question_type: 'short_answer')
        quiz.update_attribute(:question_order, [question.id])
        get quiz_path(id: quiz.id)
        expect(response).to have_http_status(:success)
      end

      it 'renders a match question' do
        question = create(:question, question_type: 'match',
                                     config: { 'left' => [{ 'id' => 'ml1', 'text' => 'CPU' },
                                                          { 'id' => 'ml2', 'text' => 'RAM' }],
                                               'right' => [{ 'id' => 'mr1', 'text' => 'Brain' },
                                                           { 'id' => 'mr2', 'text' => 'Volatile memory' },
                                                           { 'id' => 'mr3', 'text' => 'Distractor' }],
                                               'correct' => { 'ml1' => 'mr1', 'ml2' => 'mr2' } })
        quiz.update_attribute(:question_order, [question.id])
        get quiz_path(id: quiz.id)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('tjs-match')
      end
    end
  end

  describe 'scoring an answer' do
    let(:sa_question) { create(:question, topic: topic, question_type: 'short_answer') }
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [sa_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0)
    end
    let(:asked_question) { create(:asked_question, quiz: quiz, question: sa_question) }

    before do
      sa_question.answers.first.update!(text: 'cat', correct: true)
      asked_question
    end

    it 'stores a full score for a correct answer' do
      patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
      expect(asked_question.reload.score).to eq(1.0)
    end

    it 'stores a zero score for an incorrect answer' do
      patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'dog' } }
      expect(asked_question.reload.score).to eq(0.0)
    end

    it 'returns the question explanation for the reveal' do
      sa_question.update!(explanation: 'A cat is the classic example.')
      patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'dog' } }
      expect(response.parsed_body['explanation']).to eq('A cat is the classic example.')
    end
  end

  describe 'answering a drag-and-drop question' do
    let(:dd_question) do
      create(:question, topic: topic, question_type: 'drag_drop', question_text: 'A {{1}} and a {{2}}.',
                        config: { 'items' => [{ 'id' => 'i1', 'text' => 'one' }, { 'id' => 'i2', 'text' => 'two' }],
                                  'answer' => { '1' => 'i1', '2' => 'i2' } })
    end
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [dd_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0)
    end
    let(:asked_question) { create(:asked_question, quiz: quiz, question: dd_question) }

    before { asked_question }

    it 'stores a full score and the response when every blank is right' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { '1' => 'i1', '2' => 'i2' } } }
      expect(asked_question.reload).to have_attributes(score: 1.0, response: { '1' => 'i1', '2' => 'i2' })
    end

    it 'stores partial credit when one blank is wrong' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { '1' => 'i1', '2' => 'i1' } } }
      expect(asked_question.reload.score).to eq(0.5)
    end

    it 'returns the solution for the reveal' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { '1' => 'i1', '2' => 'i2' } } }
      expect(response.parsed_body['solution']).to eq('1' => 'i1', '2' => 'i2')
    end
  end

  describe 'answering a matrix question' do
    let(:matrix_question) do
      create(:question, topic: topic, question_type: 'matrix',
                        config: { 'rows' => [{ 'id' => 'r1', 'label' => 'A' }, { 'id' => 'r2', 'label' => 'B' }],
                                  'columns' => [{ 'id' => 'c1', 'label' => 'X' }, { 'id' => 'c2', 'label' => 'Y' }],
                                  'correct' => { 'r1' => ['c1'], 'r2' => ['c2'] } })
    end
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [matrix_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0)
    end
    let(:asked_question) { create(:asked_question, quiz: quiz, question: matrix_question) }

    before { asked_question }

    it 'stores a full score when every row is right' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { 'r1' => ['c1'], 'r2' => ['c2'] } } }
      expect(asked_question.reload.score).to eq(1.0)
    end

    it 'penalises over-ticking with partial credit' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { 'r1' => %w[c1 c2], 'r2' => ['c2'] } } }
      expect(asked_question.reload.score).to eq(0.75)
    end

    it 'scores an empty submission (nothing ticked) and still reveals the correct answer' do
      patch quiz_path(id: quiz.id)
      expect(response).to have_http_status(:ok)
      # Both rows leave one cell correctly blank but miss the required tick: 1 of 2 cells right per row.
      expect(asked_question.reload.score).to eq(0.5)
      # The reveal payload must carry the solution so the grid can show what should have been ticked.
      expect(response.parsed_body['solution']).to eq('r1' => ['c1'], 'r2' => ['c2'])
    end
  end

  describe 'answering a gap-fill question' do
    let(:fb_question) do
      create(:question, topic: topic, question_type: 'fill_blank', question_text: 'A {{1}} and a {{2}}.',
                        config: { 'answer' => { '1' => 'control|control unit', '2' => 'logic' } })
    end
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [fb_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0)
    end
    let(:asked_question) { create(:asked_question, quiz: quiz, question: fb_question) }

    before { asked_question }

    it 'stores a full score for a case-insensitive match against an accepted alternative' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { '1' => 'Control Unit', '2' => 'logic' } } }
      expect(asked_question.reload.score).to eq(1.0)
    end

    it 'stores partial credit when one blank is wrong' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { '1' => 'control', '2' => 'nope' } } }
      expect(asked_question.reload.score).to eq(0.5)
    end
  end

  describe 'answering an ordering question' do
    let(:order_question) do
      create(:question, topic: topic, question_type: 'ordering',
                        config: { 'items' => [{ 'id' => 'o1', 'text' => 'Fetch' },
                                              { 'id' => 'o2', 'text' => 'Decode' },
                                              { 'id' => 'o3', 'text' => 'Execute' }],
                                  'order' => %w[o1 o2 o3] })
    end
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [order_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0)
    end
    let(:asked_question) { create(:asked_question, quiz: quiz, question: order_question) }

    before { asked_question }

    it 'stores a full score for the correct sequence' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { order: %w[o1 o2 o3] } } }
      expect(asked_question.reload.score).to eq(1.0)
    end

    it 'returns the ordered solution for the reveal' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { order: %w[o1 o2 o3] } } }
      expect(response.parsed_body['solution']).to eq(%w[o1 o2 o3])
    end
  end

  describe 'answering a match question' do
    let(:match_question) do
      create(:question, topic: topic, question_type: 'match',
                        config: { 'left' => [{ 'id' => 'ml1', 'text' => 'CPU' },
                                             { 'id' => 'ml2', 'text' => 'RAM' }],
                                  'right' => [{ 'id' => 'mr1', 'text' => 'Brain of the computer' },
                                              { 'id' => 'mr2', 'text' => 'Volatile memory' },
                                              { 'id' => 'mr3', 'text' => 'Permanent storage (distractor)' }],
                                  'correct' => { 'ml1' => 'mr1', 'ml2' => 'mr2' } })
    end
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [match_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0)
    end
    let(:asked_question) { create(:asked_question, quiz: quiz, question: match_question) }

    before { asked_question }

    it 'stores a full score when every keyword is paired correctly' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { 'ml1' => 'mr1', 'ml2' => 'mr2' } } }
      expect(asked_question.reload).to have_attributes(score: 1.0, response: { 'ml1' => 'mr1', 'ml2' => 'mr2' })
    end

    it 'stores a partial score when one keyword is paired with a distractor' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { 'ml1' => 'mr3', 'ml2' => 'mr2' } } }
      expect(asked_question.reload.score).to eq(0.5)
    end

    it 'returns the left-to-right solution map for the reveal' do
      patch quiz_path(id: quiz.id), params: { answer: { structured: { 'ml1' => 'mr1', 'ml2' => 'mr2' } } }
      expect(response.parsed_body['solution']).to eq('ml1' => 'mr1', 'ml2' => 'mr2')
    end
  end

  describe 'answering a question while a cosmetic trial is active' do
    let(:sa_question) { create(:question, topic: topic, question_type: 'short_answer') }
    let(:quiz) { create(:new_quiz, user: student, question_order: [sa_question.id]) }
    let(:skin) { create(:customisation, customisation_type: 'skin', value: 'kawaii', cost: 0, image: nil) }

    before do
      create(:asked_question, quiz: quiz, question: sa_question)
      post preview_customisation_path(skin) # start a try-before-you-buy trial
    end

    it 'consumes the trial so the previewed look is dropped' do
      patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'anything' } }
      expect(session[:preview_customisation_id]).to be_nil
    end

    it 'keeps the cooldown engaged after consuming, blocking an immediate re-try' do
      patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'anything' } }
      post preview_customisation_path(skin)
      expect(session[:preview_customisation_id]).to be_nil
      expect(flash[:notice]).to match(/try another look/i)
    end
  end

  # Anti-cheat #1: a correct answer that arrives faster than a human could read is accepted but earns
  # no point and is flagged. Timing is server-set (quiz.time_last_answered), so it can't be forged.
  describe 'anti-cheat: minimum answer time' do
    let(:sa_question) { create(:question, topic: topic, question_type: 'short_answer') }
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [sa_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 3, max_streak: 3)
    end

    before do
      sa_question.answers.first.update!(text: 'cat', correct: true)
      create(:asked_question, quiz: quiz, question: sa_question, user: student)
    end

    context 'when a correct answer arrives implausibly fast' do
      before { quiz.update!(time_last_answered: Time.current) }

      it 'still scores it correct but flags it' do
        patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
        expect(AskedQuestion.last).to have_attributes(correct: true, score: 1.0, flagged_fast: true)
      end

      it 'withholds the leaderboard point' do
        allow(Quiz::AddLeaderboardPoint).to receive(:call)
        patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
        expect(Quiz::AddLeaderboardPoint).not_to have_received(:call)
      end

      it 'freezes the combo — streak neither grows nor resets' do
        patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
        expect(quiz.reload.streak).to eq(3)
      end

      it 'warns the student in the reveal payload' do
        patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
        expect(response.parsed_body['tooFast']).to be(true)
      end
    end

    context 'when a correct answer arrives at human speed' do
      before { quiz.update!(time_last_answered: 5.seconds.ago) }

      it 'is not flagged and does not warn' do
        patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
        expect(AskedQuestion.last.flagged_fast).to be(false)
        expect(response.parsed_body['tooFast']).to be(false)
      end

      it 'awards the point and advances the combo' do
        allow(Quiz::AddLeaderboardPoint).to receive(:call)
        patch quiz_path(id: quiz.id), params: { answer: { short_answer: 'cat' } }
        expect(Quiz::AddLeaderboardPoint).to have_received(:call)
        expect(quiz.reload.streak).to eq(4)
      end
    end
  end

  # Anti-cheat #3: multiple-choice buttons carry a per-quiz token, not the stable answers.id, so a
  # browser extension can't build a durable "question -> correct id" dictionary and replay it.
  describe 'anti-cheat: multiple-choice answer tokens' do
    let(:mc_question) { create(:question, topic: topic) } # 'multiple' type; factory adds a correct answer
    let(:wrong_answer) { create(:answer, question: mc_question, correct: false) }
    let(:correct_answer) { mc_question.answers.find(&:correct) }
    let(:quiz) do
      create(:new_quiz, user: student, question_order: [mc_question.id], counts_for_leaderboard: false,
                        answered_correct: 0, streak: 0, max_streak: 0, time_last_answered: 5.seconds.ago)
    end

    def token_for(answer)
      Quiz::AnswerToken.for(quiz_id: quiz.id, question_id: mc_question.id, answer_id: answer.id)
    end

    before do
      wrong_answer
      create(:asked_question, quiz: quiz, question: mc_question, user: student)
    end

    it 'scores a correct answer submitted as its per-quiz token' do
      patch quiz_path(id: quiz.id), params: { answer: { id: token_for(correct_answer) } }
      expect(AskedQuestion.last).to have_attributes(correct: true, score: 1.0)
    end

    it 'does not score a submission of the raw database id — the dictionary key is useless' do
      patch quiz_path(id: quiz.id), params: { answer: { id: correct_answer.id.to_s } }
      expect(AskedQuestion.last.correct).to be_nil
    end

    it 'reveals correct answers as tokens, never raw ids' do
      patch quiz_path(id: quiz.id), params: { answer: { id: token_for(wrong_answer) } }
      revealed = response.parsed_body['answer'].first
      expect(revealed).to eq('token' => token_for(correct_answer), 'text' => correct_answer.text)
      expect(revealed).not_to have_key('id')
    end

    it 'rotates the token for the same answer across different quizzes' do
      other = create(:new_quiz, user: student, question_order: [mc_question.id])
      expect(token_for(correct_answer))
        .not_to eq(Quiz::AnswerToken.for(quiz_id: other.id, question_id: mc_question.id,
                                         answer_id: correct_answer.id))
    end
  end
end
