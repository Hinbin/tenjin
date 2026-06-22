# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StudentQuestionStatistic, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:question) }

  it 'builds a valid record from the factory' do
    expect(build(:student_question_statistic)).to be_valid
  end
end
