RSpec.describe 'Student completes a homework', type: :feature, js: true, default_creates: true do
  before do
    setup_subject_database
    sign_in student
  end

  context 'when looking at the challenges' do
    let(:homework_ten_percent) { create(:homework, topic: topic, classroom: classroom, required: 10) }
    let(:quiz) { create(:new_quiz) }

    before do
      homework_ten_percent
      answer
    end

    it 'lets me complete a homwork' do
      visit(dashboard_path)
      find(:css, '.homework-row[data-homework="' + homework_ten_percent.id.to_s + '"]').click
      first(class: 'question-button').click
      first(class: 'next-button').click
      expect(page).to have_css('.homework-row > td > i.fa-check')
    end
  end
end
