# frozen_string_literal: true

# Audit record for one question-import API call: which topic and source file it targeted,
# the token that authenticated it, and the resulting counts/errors. One row per POST.
class Import < ApplicationRecord
  belongs_to :topic
end
