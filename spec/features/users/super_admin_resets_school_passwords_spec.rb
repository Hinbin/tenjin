RSpec.describe 'School admin views student list', type: :feature, js: true do
  include_context 'default_creates'

  before do
    sign_in create(:admin, role: 'super')
    school
    create_list(:student, 5, school: school)
    create_list(:teacher, 2, school: school)
  end

end
