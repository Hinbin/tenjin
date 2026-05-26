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
    described_class.call(JSON.generate(multiple_lessons), topic, topic_filename)
  end

  it "imports all questions successfully" do
    expect(import_multiple_lessons.success?).to be true
  end

  it "imports boolean questions" do
    result = described_class.call(JSON.generate([build(:question_import_hash_boolean)]), topic, topic_filename)
    expect(result.success?).to be true
  end

  it "imports questions with no lesson information" do
    result = described_class.call(JSON.generate(no_lessons), topic, topic_filename)
    expect(result.success?).to be true
  end

  it "reports the number of questions imported" do
    expect(import_multiple_lessons.number_questions_imported).to eq(multiple_lessons.length)
  end

  it "saves questions to the database" do
    expect { import_multiple_lessons }.to change(Question, :count).by(multiple_lessons.length)
  end

  it "saves four answers per question to the database" do
    expect { import_multiple_lessons }.to change(Answer, :count).by(multiple_lessons.length * 4)
  end

  it "creates a lesson for each unique lesson name" do
    expect { import_multiple_lessons }.to change(Lesson, :count).by(multiple_lessons.length)
  end

  it "assigns the lesson name from the import data" do
    import_multiple_lessons
    expect(Lesson.first.title).to eq(multiple_lessons[0]["lesson"])
  end

  context "when question type is missing" do
    before { multiple_lessons[0] = multiple_lessons[0].except("question_type") }

    it "fails validation" do
      expect(import_multiple_lessons.success?).to be false
    end
  end

  context "when question text is blank" do
    before { multiple_lessons[0]["question_text"] = "" }

    it "fails validation" do
      expect(import_multiple_lessons.success?).to be false
    end
  end

  context "with an existing lesson matching the import data" do
    before do
      create(:lesson, title: single_lesson[0]["lesson"], topic: topic, category: :no_content, video_id: "")
    end

    it "assigns questions to the existing lesson without creating a duplicate" do
      expect {
        described_class.call(JSON.generate(single_lesson), topic, topic_filename)
      }.not_to change(Lesson, :count)
    end

    it "creates questions under the existing lesson" do
      expect {
        described_class.call(JSON.generate(single_lesson), topic, topic_filename)
      }.to change(Question, :count).by(single_lesson.length)
    end
  end
end
