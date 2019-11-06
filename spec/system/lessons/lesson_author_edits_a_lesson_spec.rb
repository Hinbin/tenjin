# frozen_string_literal: true

RSpec.describe 'Lesson author edits a lesson', type: :system, js: true, default_creates: true do
  let(:second_subject) { create(:subject) }
  let(:lesson) { create(:lesson, topic: topic) }
  let(:new_lesson) { build(:lesson, topic: topic) }

  def fill_in_form(lesson)
    fill_in('URL', with: lesson.video_id)
    fill_in('Title', with: lesson.title)
    select lesson.topic.name, from: 'Topic'
  end

  before do
    sign_in teacher
    lesson
  end

  it 'shows an option to edit lessons when I allowed to' do
    teacher.add_role :lesson_author, subject
    visit(lessons_path)
    expect(page).to have_link('Edit')
  end

  it 'only shows an option to edit lessons if I am allowed to' do
    visit(lessons_path)
    expect(page).to have_no_link('Edit')
  end

  it 'shows subjects that I can author a lesson for' do
    teacher.add_role :lesson_author, subject
    visit(lessons_path)
    expect(page).to have_css('h1', text: 'CREATE LESSONS').and have_css('h3', text: subject.name)
  end

  it 'only shows subjects that I can author a lesson for' do
    teacher.add_role :lesson_author, subject
    second_subject
    visit(lessons_path)
    expect(page).to have_css('h1', text: 'CREATE LESSONS').and have_no_css('h3', text: second_subject.name)
  end

  context 'when adding a lesson' do
    let(:new_lesson_bad_content) { build(:lesson, topic: topic, video_id: 'https://redtube.com/t-ZRX8984sc') }
    let(:new_lesson_vimeo) { build(:lesson, topic: topic, video_id: 'https://vimeo.com/371104836') }

    before do
      teacher.add_role :lesson_author, subject
      topic
    end

    it 'allows me to create a lesson for a subject' do
      visit(lessons_path)
      click_link("Create #{subject.name} Lesson")
      expect(current_path).to eq(new_lesson_path)
    end

    it 'prevents me putting in a link to a bad website' do
      visit(new_lesson_path(subject: subject))
      fill_in_form(new_lesson_bad_content)
      click_button('Create Lesson')
      expect(page).to have_content('Must be a YouTube or Vimeo link')
    end

    it 'allows me to create a lesson' do
      visit(new_lesson_path(subject: subject))
      fill_in_form(new_lesson)
      click_button('Create Lesson')
      expect(page).to have_css('.videoLink', count: 2)
    end

    it 'allows me to create a vimeo lesson' do
      visit(new_lesson_path(subject: subject))
      fill_in_form(new_lesson_vimeo)
      click_button('Create Lesson')
      expect(page).to have_css('.videoLink', count: 2)
    end
  end

  context 'when editing existings lesson' do
    before do
      setup_subject_database
      teacher.add_role :lesson_author, subject
    end

    it 'saves new lesson details' do
      visit(lessons_path)
      click_link('Edit')
      fill_in_form(new_lesson)
      click_button('Update Lesson')
      expect(page).to have_css(".videoLink[src=\"#{Lesson.last.generate_video_src}\"]")
    end

    it 'deleted lessons' do
      visit(lessons_path)
      page.accept_confirm do
        click_link('Delete')
      end
      expect(page).to have_no_css('.videoLink')
    end

  end
end
