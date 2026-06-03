# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppErrorReporter do
  it 'records exception details and context' do
    error = StandardError.new('quiz exploded')
    error.set_backtrace(['app/services/quiz/create_quiz.rb:1'])

    expect do
      described_class.report(error, context: { quiz_id: 123 })
    end.to change(AppError, :count).by(1)

    app_error = AppError.last
    expect(app_error.exception_class).to eq('StandardError')
    expect(app_error.message).to eq('quiz exploded')
    expect(app_error.context).to include('quiz_id' => 123)
  end
end
