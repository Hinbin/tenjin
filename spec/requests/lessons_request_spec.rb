# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Lessons', :default_creates, type: :request do
  let(:lesson) { create(:lesson, topic:) }
  let(:second_subject) { create(:subject) }
  let(:second_topic) { create(:topic, subject: second_subject) }
  let(:not_enrolled_lesson) { create(:lesson, topic: second_topic) }
  let(:lesson_no_content) { create(:lesson, topic:, category: 'no_content', video_id: nil) }

  before do
    create(:enrollment, classroom:, user: student)
    create(:multiplier)
    sign_in student
    lesson
  end

  it 'shows videos for subjects I am enrolled for' do
    get lessons_path
    html = Capybara.string(response.body)
    expect(html).to have_css('.subject-title', text: lesson.subject.name)
  end

  it 'only shows videos for subjects I am enrolled for' do
    not_enrolled_lesson
    get lessons_path
    html = Capybara.string(response.body)
    expect(html).to have_no_css('.subject-title', text: not_enrolled_lesson.subject.name)
  end

  it 'ignores lessons with no video link' do
    lesson_no_content
    get lessons_path
    expect(response.body).not_to include(lesson_no_content.title)
  end
end
