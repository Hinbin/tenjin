# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson, type: :model do
  it { is_expected.to have_many(:questions) }
end
