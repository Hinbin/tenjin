RSpec.describe 'User customises the site', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
  end

  context 'when visiting the customisation page from the navbar' do
    it 'visits from the customise link' do
      visit(dashboard_path)
      find('a', text: 'Customise').click
      expect(page).to have_current_path(customise_path)
    end

    it 'visits from the challenge star' do
      visit(dashboard_path)
      find('i.fa-star').click
      expect(page).to have_current_path(customise_path)
    end

    it 'visits from the number of points' do
      visit(dashboard_path)
      find('#challenge-points').click
      expect(page).to have_current_path(customise_path)
    end
  end

  context 'when looking at available dashboard styles' do
    let(:dashboard_orange) { create(:customisation) }

    it 'shows available dashboard customisations' do
      dashboard_orange
      visit(customise_path)
      expect(page).to have_content(dashboard_orange.name)
    end
  end
end
