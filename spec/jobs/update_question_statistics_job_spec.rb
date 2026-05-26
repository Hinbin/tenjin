# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateQuestionStatisticsJob, :default_creates do
  let(:quiz) { create(:quiz, active: false, user: student) }
  let(:question) { create(:question) }
  let(:question_statistic) { QuestionStatistic.find_by!(question: question) }

  context "when question answered correctly" do
    context "with no existing statistic" do
      let!(:asked_question) { create(:asked_question, question: question, correct: true, quiz: quiz) }

      before { described_class.perform_now }

      it "sets number_asked to 1" do
        expect(question_statistic.number_asked).to eq(1)
      end

      it "sets number_correct to 1" do
        expect(question_statistic.number_correct).to eq(1)
      end
    end

    context "with an existing statistic" do
      let!(:existing_statistic) { create(:question_statistic, question: question) }
      let!(:asked_question) { create(:asked_question, question: question, correct: true, quiz: quiz) }

      it "increments number_correct" do
        expect { described_class.perform_now }.to change { existing_statistic.reload.number_correct }.by(1)
      end

      it "increments number_asked" do
        expect { described_class.perform_now }.to change { existing_statistic.reload.number_asked }.by(1)
      end
    end
  end

  context "when question answered incorrectly" do
    context "with no existing statistic" do
      let!(:asked_question) { create(:asked_question, question: question, correct: false, quiz: quiz) }

      before { described_class.perform_now }

      it "sets number_asked to 1" do
        expect(question_statistic.number_asked).to eq(1)
      end

      it "sets number_correct to 0" do
        expect(question_statistic.number_correct).to eq(0)
      end
    end

    context "with an existing statistic" do
      let!(:existing_statistic) { create(:question_statistic, question: question) }
      let!(:asked_question) { create(:asked_question, question: question, correct: false, quiz: quiz) }

      it "does not increment number_correct" do
        expect { described_class.perform_now }.not_to change { existing_statistic.reload.number_correct }
      end

      it "increments number_asked" do
        expect { described_class.perform_now }.to change { existing_statistic.reload.number_asked }.by(1)
      end
    end
  end

  describe "asked question cleanup" do
    let!(:asked_question) { create(:asked_question, question: question, correct: true, quiz: quiz) }

    it "removes old asked questions" do
      expect { described_class.perform_now }.to change(AskedQuestion, :count).by(-1)
    end

    context "when the quiz is still active" do
      let(:quiz) { create(:quiz, active: true) }

      it "does not process the asked question" do
        expect { described_class.perform_now }.not_to change(AskedQuestion, :count)
      end
    end
  end

  context "when updating user statistics" do
    let!(:asked_question) { create(:asked_question, question: question, correct: true, quiz: quiz) }
    let(:current_user_statistic) do
      create(:user_statistic, user: student, week_beginning: Date.current.beginning_of_week)
    end
    let(:old_user_statistic) do
      create(:user_statistic, user: student, week_beginning: (Date.current - 1.month).beginning_of_week)
    end

    it "creates a user statistic if needed" do
      expect { described_class.perform_now }.to change(UserStatistic, :count).by(1)
    end

    it "assigns the user to the new statistic" do
      described_class.perform_now
      expect(UserStatistic.find_by!(user: student).user).to eq(student)
    end

    it "updates the user statistic for the current week" do
      expect { described_class.perform_now }.to change { current_user_statistic.reload.questions_answered }.by(1)
    end

    context "with an existing statistic for an older week" do
      let!(:old_user_statistic) do
        create(:user_statistic, user: student, week_beginning: (Date.current - 1.month).beginning_of_week)
      end

      it "does not change older statistics" do
        expect { described_class.perform_now }.not_to change { old_user_statistic.reload.questions_answered }
      end

      it "creates a new user statistic" do
        expect { described_class.perform_now }.to change(UserStatistic, :count).by(1)
      end
    end

    context "when a user statistic already exists for the current week" do
      it "does not create a duplicate statistic"
    end
  end
end
