# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#subject_image_tag' do
    it 'renders the subject image for a known subject' do
      expect(helper.subject_image_tag('Computer Science')).to include('computer-science')
    end

    it 'renders the default image for a subject without a matching asset' do
      expect(helper.subject_image_tag('Science')).to include('default-subject')
    end

    it 'does not match a longer asset name as a substring' do
      expect(helper.subject_image_tag('Ience')).to include('default-subject')
    end

    it 'degrades to the default image if image_pack_tag raises a missing entry' do
      allow(helper).to receive(:image_pack_tag).and_call_original
      allow(helper).to receive(:image_pack_tag)
        .with('images/does-not-exist.jpg', any_args)
        .and_raise(Shakapacker::Manifest::MissingEntryError)
      allow(helper).to receive(:image_pack_tag)
        .with('images/default-subject.jpg', any_args)
        .and_call_original

      expect(helper.subject_image_tag('Does Not Exist')).to include('default-subject')
    end
  end
end
