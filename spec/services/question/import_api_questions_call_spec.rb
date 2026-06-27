# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question::ImportApiQuestions, '#call', :default_creates do
  def run(payload, target: topic, filename: 'systems')
    described_class.call(payload.to_json, target, filename:, token_label: 'question-engine')
  end

  it 'imports questions as pending and inactive' do
    run(ImportPayloads.all_engine_types)

    expect(topic.questions).to all(have_attributes(review_status: 'pending', active: false))
  end

  it 'reports imported and skipped counts' do
    result = run([ImportPayloads.short_answer, ImportPayloads.multiple.merge(question_text: '')])

    expect(result).to have_attributes(imported: 1, updated: 0, skipped: 1)
    expect(result.errors.size).to eq(1)
  end

  it 'upserts by external_id within the topic' do
    run([ImportPayloads.short_answer])
    result = run([ImportPayloads.short_answer(external_id: 1001)])

    expect(Question.where(external_id: 1001, topic:).count).to eq(1)
    expect(result).to have_attributes(imported: 0, updated: 1)
  end

  it 'replaces answers on re-push rather than appending them' do
    run([ImportPayloads.multiple])
    run([ImportPayloads.multiple])

    expect(Question.find_by(external_id: 1002).answers.count).to eq(2)
  end

  it 'never renames the destination topic' do
    expect { run(ImportPayloads.all_engine_types, filename: 'something-else') }
      .not_to(change { topic.reload.name })
  end

  it 'writes one audit row per call' do
    expect { run(ImportPayloads.all_engine_types) }.to change(Import, :count).by(1)
    expect(Import.last).to have_attributes(topic:, imported_count: 6, skipped_count: 0)
  end

  it 'rejects a body that is not a JSON array' do
    result = described_class.call('{"not":"an array"}', topic, filename: 'x')

    expect(result).to have_attributes(imported: 0, updated: 0)
    expect(result.errors).not_to be_empty
  end
end
