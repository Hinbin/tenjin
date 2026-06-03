# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'School admin sets up classrooms', :default_creates, :js, type: :system do
  context 'when configuring classrooms' do
    let(:classroom) { create(:classroom, school:) }
    let(:subject) { create(:subject) }

    before do
      classroom
      sign_in school_admin
    end

    it 'allows me to set a subject to this classroom' do
      subject
      visit(classrooms_path)
      select subject.name, from: 'subject'
      visit(classrooms_path)
      expect(page).to have_text(subject.name)
    end

    it 'tells me when I need to sync the school' do
      subject
      visit(classrooms_path)
      select subject.name, from: 'subject'
      expect(page).to have_text('School sync required. Click here to start')
    end
  end
end
