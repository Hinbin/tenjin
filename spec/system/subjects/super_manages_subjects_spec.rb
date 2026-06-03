# frozen_string_literal: true

require 'rails_helper'

# JS-only Selenium smoke tests for subject management.
# Non-interactive tests have been converted to spec/requests/subject_request_spec.rb.
RSpec.describe 'Super manages subjects', type: :system, js: true, default_creates: true do
  before do
    sign_in super_admin
    subject
  end

  context 'when managing an individual subject' do
    def deactivate_subject
      visit(subject_path(subject))
      click_link('Deactivate Subject')
      page.accept_alert
      find('table#active-subjects')
    end

    it 'allows an admin to deactivate a subject' do
      deactivate_subject
      expect(page).to have_css('#deactivated-subjects tr td', text: subject.name)
    end

    context 'when deactivating a quiz' do
      let(:enrollment) { create(:enrollment, classroom:, user: student, subject:) }

      before { enrollment }

      it 'stops students from taking a quiz' do
        deactivate_subject
        sign_out super_admin
        sign_in student
        visit(dashboard_path)
        expect(page).to have_no_content(subject.name)
      end

      it 'reassigns classrooms to nil' do
        deactivate_subject
        sign_out super_admin
        sign_in school_admin
        visit(classrooms_path)
        expect(page).to have_no_content(subject.name)
      end
    end
  end
end
