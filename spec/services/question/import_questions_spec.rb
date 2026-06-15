# frozen_string_literal: true

require "rails_helper"

RSpec.describe Question::ImportQuestions, :default_creates do
  let(:lesson_name) { FFaker::Lorem.words.join }
  let(:single_question) { build(:question_import_hash_with_lesson) }
  let(:single_lesson) { build_list(:question_import_hash_with_lesson, rand(1..10), lesson: lesson_name) }
  let(:multiple_lessons) { build_list(:question_import_hash_with_lesson, rand(1..10)) }
  let(:no_lessons) { build_list(:question_import_hash, rand(1..10)) }
  let(:topic_filename) { "#{topic.name}.json" }

  def import_multiple_lessons
    described_class.call(data: JSON.generate(multiple_lessons), topic: topic, filename: topic_filename)
  end

  it "imports questions, answers, and lessons" do
    expect { import_multiple_lessons }
      .to change(Question, :count).by(multiple_lessons.length)
      .and change(Answer, :count).by(multiple_lessons.length * 4)
      .and change(Lesson, :count).by(multiple_lessons.length)
  end

  it "returns success with the imported count and assigns the lesson title from the data" do
    result = import_multiple_lessons
    expect(result).to be_success
    expect(result.payload[:number_questions_imported]).to eq(multiple_lessons.length)
    expect(Lesson.first.title).to eq(multiple_lessons[0]["lesson"])
  end

  it "imports boolean questions" do
    result = described_class.call(data: JSON.generate([build(:question_import_hash_boolean)]), topic: topic, filename: topic_filename)
    expect(result).to be_success
  end

  it "imports questions with no lesson information" do
    result = described_class.call(data: JSON.generate(no_lessons), topic: topic, filename: topic_filename)
    expect(result).to be_success
  end

  context "when question type is missing" do
    before { multiple_lessons[0] = multiple_lessons[0].except("question_type") }

    it "fails validation with a missing-key error" do
      result = import_multiple_lessons
      expect(result).to be_failure
      expect(result.error).to match(/Question missing key/)
    end
  end

  context "when question text is blank" do
    before { multiple_lessons[0]["question_text"] = "" }

    it "fails validation" do
      expect(import_multiple_lessons).to be_failure
    end
  end

  context "when answers is not an array" do
    before { multiple_lessons[0]["answers"] = "not an array" }

    it "fails validation with an answers-not-array error" do
      result = import_multiple_lessons
      expect(result).to be_failure
      expect(result.error).to match(/Answers for question not in array/)
    end
  end

  context "when an answer is missing the text key" do
    before { multiple_lessons[0]["answers"][0] = multiple_lessons[0]["answers"][0].except("text") }

    it "fails validation with a missing-text error" do
      result = import_multiple_lessons
      expect(result).to be_failure
      expect(result.error).to match(/Text key missing for answer/)
    end
  end

  context "with an existing lesson matching the import data" do
    before do
      create(:lesson, title: single_lesson[0]["lesson"], topic: topic, category: :no_content, video_id: "")
    end

    it "assigns questions to the existing lesson without creating a duplicate" do
      expect {
        described_class.call(data: JSON.generate(single_lesson), topic: topic, filename: topic_filename)
      }.not_to change(Lesson, :count)
    end

    it "creates questions under the existing lesson" do
      expect {
        described_class.call(data: JSON.generate(single_lesson), topic: topic, filename: topic_filename)
      }.to change(Question, :count).by(single_lesson.length)
    end
  end
end
