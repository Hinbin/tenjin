# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Analytics::QuestionDifficulty do
  describe '.call' do
    context 'with no statistics (prior only)' do
      it 'uses the type prior verbatim for an unsampled question' do
        question = create(:question, question_type: 'multiple')

        outcome = described_class.call(question)

        expect(outcome.difficulty).to eq(described_class::TYPE_PRIOR['multiple'])
      end

      it 'ranks the harder structured types above MCQ on the prior alone' do
        # `build` (not `create`): the engine only reads question_type, so we skip the structured-
        # config validation that real matrix questions require — it is irrelevant to difficulty.
        mcq = build(:question, question_type: 'multiple')
        matrix = build(:question, question_type: 'matrix')

        expect(described_class.call(matrix).difficulty)
          .to be > described_class.call(mcq).difficulty
        expect(described_class.call(matrix).band).to eq(:hard)
      end

      it 'falls back to the default prior for a type with no entry' do
        question = create(:question, question_type: 'multiple')
        # Simulate the retired :boolean (enum value 1) that has no prior entry.
        question.update_column(:question_type, 1)

        outcome = described_class.call(question.reload)

        expect(outcome.difficulty).to eq(described_class::DEFAULT_PRIOR)
      end
    end

    context 'when the question is well sampled (empirical dominant)' do
      it 'tracks the observed score, not the type prior' do
        question = create(:question, question_type: 'multiple')
        # 1000 attempts, 20% mean score => empirical difficulty 0.8, far from the 0.25 prior.
        create(:question_statistic, question: question, number_asked: 1000,
                                    number_correct: 200, score_sum: 200.0)

        outcome = described_class.call(question)

        expect(outcome.difficulty).to be_within(0.02).of(0.8)
        expect(outcome.band).to eq(:hard)
      end

      it 'honours partial credit via score_sum rather than number_correct' do
        question = create(:short_answer_question)
        # Nobody is fully correct, but the cohort averages half marks => empirical difficulty 0.5.
        create(:question_statistic, question: question, number_asked: 1000,
                                    number_correct: 0, score_sum: 500.0)

        expect(described_class.call(question).difficulty).to be_within(0.02).of(0.5)
      end
    end

    context 'when shrinking by sample size' do
      it 'sits halfway between empirical and prior at exactly K attempts' do
        question = create(:question, question_type: 'multiple')
        k = described_class::SHRINKAGE_K
        # Empirical difficulty 1.0 (all wrong); prior 0.25; weight at n=K is 0.5.
        create(:question_statistic, question: question, number_asked: k,
                                    number_correct: 0, score_sum: 0.0)

        expected = (0.5 * 1.0) + (0.5 * described_class::TYPE_PRIOR['multiple'])
        expect(described_class.call(question).difficulty).to be_within(0.001).of(expected)
      end

      it 'stays near the prior when only lightly sampled' do
        question = create(:question, question_type: 'multiple')
        create(:question_statistic, question: question, number_asked: 1,
                                    number_correct: 0, score_sum: 0.0)

        # One brutal attempt should barely move a 0.25-prior MCQ.
        expect(described_class.call(question).difficulty).to be < 0.35
      end
    end

    context 'when classifying band boundaries' do
      def difficulty_for_score(mean_score)
        question = create(:question, question_type: 'multiple')
        # Heavy sample so empirical dominates and difficulty ~= 1 - mean_score.
        asked = 100_000
        create(:question_statistic, question: question, number_asked: asked,
                                    number_correct: 0, score_sum: mean_score * asked)
        described_class.call(question)
      end

      it 'classifies low difficulty as easy' do
        expect(difficulty_for_score(0.9).band).to eq(:easy)   # difficulty ~0.1
      end

      it 'classifies mid difficulty as medium' do
        expect(difficulty_for_score(0.5).band).to eq(:medium) # difficulty ~0.5
      end

      it 'classifies high difficulty as hard' do
        expect(difficulty_for_score(0.1).band).to eq(:hard)   # difficulty ~0.9
      end
    end

    context 'with batch input' do
      it 'returns a hash keyed by question id' do
        easy = create(:question, question_type: 'multiple')
        hard = create(:short_answer_question)

        outcome = described_class.call([easy.id, hard.id])

        expect(outcome.difficulties.keys).to contain_exactly(easy.id, hard.id)
        expect(outcome.difficulties[hard.id][:difficulty])
          .to be > outcome.difficulties[easy.id][:difficulty]
      end

      it 'loads statistics in a single query (no N+1)' do
        questions = create_list(:question, 3, question_type: 'multiple')
        questions.each { |q| create(:question_statistic, question: q) }

        relation = Question.where(id: questions.map(&:id))

        stats_queries = 0
        counter = lambda do |_name, _start, _finish, _id, payload|
          stats_queries += 1 if payload[:sql].include?('question_statistics')
        end

        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
          described_class.call(relation)
        end

        expect(stats_queries).to eq(1)
      end

      it 'accepts an ActiveRecord relation' do
        question = create(:question, question_type: 'multiple')

        outcome = described_class.call(Question.where(id: question.id))

        expect(outcome.difficulties).to have_key(question.id)
      end
    end
  end
end
