# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question::ImportQuestions, '#call', default_creates: true do
  context 'when importing questions' do
    let(:lesson_name) { FFaker::Lorem.words.join }
    let(:single_question) { build(:question_import_hash_with_lesson) }

    let(:single_lesson) { build_list(:question_import_hash_with_lesson, rand(1..10), lesson: lesson_name) }
    let(:multiple_lessons) { build_list(:question_import_hash_with_lesson, rand(1..10)) }
    let(:no_lessons) { build_list(:question_import_hash, rand(1..10)) }
    let(:topic_filename) { "#{topic.name}.json" }
    

    it 'validates questions successfully' do
      result = described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(result.success?).to eq(true)
    end

    it 'imports boolean questions' do
      result = described_class.new(JSON.generate([build(:question_import_hash_boolean)]), topic, topic_filename).call
      expect(result.success?).to eq(true)
    end

    it 'reports number of questions added' do
      result = described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(result.number_questions_imported).to eq(multiple_lessons.length)
    end

    it 'saves questions to the database' do
      described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(Question.count).to eq(multiple_lessons.length)
    end

    it 'saves answers to the database' do
      described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(Answer.count).to eq(multiple_lessons.length * 4)
    end

    it 'fails validation for missing question type' do
      multiple_lessons[0] = multiple_lessons[0].except('question_type')
      result = described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(result.success?).to eq(false)
    end

    it 'fails validation for missing question text body' do
      multiple_lessons[0]['question_text'] = ''
      result = described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(result.success?).to eq(false)
    end

    it 'assigns the correct lesson name' do
      described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(Lesson.first.title).to eq(multiple_lessons[0]['lesson'])
    end

    it 'assigns questions to existing lessons' do
      create(:lesson, title: single_lesson[0]['lesson'], topic: topic, category: :no_content, video_id: '')
      described_class.new(JSON.generate(single_lesson), topic, topic_filename).call
      expect(Lesson.count).to eq(1)
    end

    it 'creates multiple lessons' do
      described_class.new(JSON.generate(multiple_lessons), topic, topic_filename).call
      expect(Lesson.count).to eq(multiple_lessons.count)
    end

    it 'creates questions with existing lessons' do
      create(:lesson, title: single_lesson[0]['lesson'], topic: topic, category: :no_content, video_id: '')
      described_class.new(JSON.generate(single_lesson), topic, topic_filename).call
      expect(Question.count).to eq(single_lesson.length)
    end

    it 'adds questions with no lesson information' do
      result = described_class.new(JSON.generate(no_lessons), topic, topic_filename).call
      expect(result.success?).to eq(true)
    end
  end
end
