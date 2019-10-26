RSpec.describe 'Super manages a school', :focus, type: :system, js: true, default_creates: true do
  let(:second_subject) { create(:subject) }

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

end