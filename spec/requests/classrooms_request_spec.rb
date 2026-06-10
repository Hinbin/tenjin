# frozen_string_literal: true

require "rails_helper"

RSpec.describe "classrooms controller", :default_creates do
  describe "PATCH /classrooms/:id" do
    before { sign_in school_admin }

    let(:new_subject) { create(:subject) }

    it "assigns the chosen subject to the classroom" do
      expect { patch classroom_path(classroom), params: {subject: new_subject.id} }
        .to change { classroom.reload.subject }.from(quiz_subject).to(new_subject)
    end

    it "marks the school as needing a sync" do
      expect { patch classroom_path(classroom), params: {subject: new_subject.id} }
        .to change { school.reload.sync_status }.to("needed")
    end
  end
end
