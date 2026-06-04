# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#print_subject_image' do
    it 'returns the asset when it exists exactly in the manifest' do
      expect(helper.print_subject_image('computer-science.jpg')).to eq('computer-science.jpg')
    end

    it 'falls back to the default when the asset is missing' do
      expect(helper.print_subject_image('nonexistent.jpg')).to eq('default-subject.jpg')
    end

    it 'does not match a longer asset name as a substring' do
      # "science.jpg" must not be matched by "computer-science.jpg" in the manifest
      expect(helper.print_subject_image('science.jpg')).to eq('default-subject.jpg')
    end
  end

  describe '#subject_image_tag' do
    it 'renders the subject image for a known subject' do
      expect(helper.subject_image_tag('Computer Science')).to include('computer-science')
    end

    it 'renders the default image for a subject without a matching asset' do
      expect(helper.subject_image_tag('Science')).to include('default-subject')
    end

    it 'degrades to the default image if image_pack_tag raises a missing entry' do
      allow(helper).to receive(:image_pack_tag).and_call_original
      allow(helper).to receive(:image_pack_tag)
        .with('does-not-exist.jpg', any_args)
        .and_raise(Webpacker::Manifest::MissingEntryError)
      allow(helper).to receive(:print_subject_image).and_return('does-not-exist.jpg')

      expect(helper.subject_image_tag('Anything')).to include('default-subject')
    end
  end
end
