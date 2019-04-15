RSpec.describe 'User customises the site', type: :feature, js: true, default_creates: true do

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
    let(:dashboard_customisation) { create(:customisation, cost: 6) }
    let(:student) { create(:user, school: school, challenge_points: 10) }

    before do
      dashboard_customisation
      visit(customise_path)
    end

    it 'shows available dashboard customisations' do
      expect(page).to have_content(dashboard_customisation.name.upcase)
    end

    it 'allows you to buy a dashbord style' do
      find('button#buy-dashboard-' + dashboard_customisation.value).click
      find('section#homework-' + dashboard_customisation.value)
      expect(student.reload.dashboard_style).to eq(dashboard_customisation.value)
    end

    it 'deducts the required amount of challenge points' do
      find('button#buy-dashboard-' + dashboard_customisation.value).click
      expect{student.reload}.to change(student, :challenge_points).by(-dashboard_customisation.cost)
    end
  end
end
