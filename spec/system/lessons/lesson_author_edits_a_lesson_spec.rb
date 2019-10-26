# frozen_string_literal: true

RSpec.describe 'Lesson author edits a lesson', type: :system, js: true, default_creates: true do
  let(:second_subject) { create(:subject) }

  def fill_in_form(lesson)
    fill_in('Title', with: lesson.title)
    fill_in('YouTube URL', with: lesson.url)
    select lesson.topic.name, from: 'Topic'
  end

  before do
    sign_in teacher
  end

  it 'shows an option to edit lessons when I allowed to' do
    teacher.add_role :lesson_author, subject
    visit(lessons_path)
    expect(page).to have_css('h1', text: 'Edit Lessons')
  end

  it 'does not show an option to edit lessons if I am not allowed to' do
    visit(lessons_path)
    expect(page).to have_no_css('h1', text: 'Edit Lessons')
  end

  it 'shows subjects that I can author a lesson for' do
    teacher.add_role :lesson_author, subject
    visit(lessons_path)
    expect(page).to have_css('h1', text: 'Edit Lessons').and have_css('h3', text: subject.name)
  end

  it 'only shows subjects that I can author a lesson for' do
    teacher.add_role :lesson_author, subject
    second_subject
    visit(lessons_path)
    expect(page).to have_css('h1', text: 'Edit Lessons').and have_no_css('h3', text: second_subject.name)
  end

  context 'when adding a lesson' do
    let(:new_lesson) { build(:lesson, topic: topic) }
    let(:new_lesson_bad_content) { build(:lesson, topic: topic, url: 'http://redtube.com/t-ZRX8984sc') }

    before do
      teacher.add_role :lesson_author, subject
      topic
    end

    it 'allows me to add a lesson to a subject' do
      visit(lessons_path)
      click_button('Add Lesson')
      expect(page).to have_path(new_lesson_path)
    end

    it 'prevents me putting in a link to a bad website' do
      visit(new_lesson_path(subject: subject))
      fill_in_form(new_lesson_bad_content)
      click_button('Create Lesson')
      expect(page).to have_content('Must be a YouTube video link')
    end

    it 'allows me to create a lesson', :focus do
      visit(new_lesson_path(subject: subject))
      fill_in_form(new_lesson)
      click_button('Create Lesson')
      expect(page).to have_css('h3', exact_text: new_lesson.title)
    end
  end
end
