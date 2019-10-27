# frozen_string_literal: true

RSpec.describe 'User views a lesson', type: :system, js: true, default_creates: true do
  let(:second_subject) { create(:subject) }
  let(:second_topic) { create(:topic, subject: second_subject) }
  let(:not_enrolled_lesson) { create(:lesson, topic: second_topic) }
  let(:lesson) { create(:lesson, topic: topic) }

  before do
    setup_subject_database
    sign_in student
    lesson
  end

  it 'shows videos for subjects I am enrolled for' do
    visit(lessons_path)
    expect(page).to have_css('h1', text: lesson.subject.name)
  end

  it 'only shows videos for subjects I am enrolled for' do
    not_enrolled_lesson
    visit(lessons_path)
    expect(page).to have_no_css('h1', text: not_enrolled_lesson.subject.name)
  end

  it 'plays the video when clicked on' do
    visit(lessons_path)
    find(:css, 'div.card.videoLink').click
    expect(page).to have_css("iframe[src^=\"http://www.youtube.com/embed/#{lesson.video_id}?autoplay=1\"]")
  end

  it 'creates a quiz for the video if I choose to'
end
