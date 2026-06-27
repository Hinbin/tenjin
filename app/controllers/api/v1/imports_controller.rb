# frozen_string_literal: true

# Token-authenticated import endpoint for the external Question Engine. Imports land in the
# review queue (pending + inactive) until a human approves them — see Question::ImportApiQuestions.
class Api::V1::ImportsController < ActionController::API
  TOKEN_LABEL = 'question-engine'

  before_action :authenticate_token!

  def create
    topic = Topic.find_by(id: params[:topic_id])
    return render(json: { errors: ['Unknown topic'] }, status: :not_found) if topic.nil?

    result = Question::ImportApiQuestions.call(
      request.raw_post, topic,
      filename: params[:filename], token_label: TOKEN_LABEL
    )

    render json: import_body(result), status: import_status(result)
  end

  private

  def import_body(result)
    { imported: result.imported, updated: result.updated,
      skipped: result.skipped, errors: result.errors }
  end

  # 200 when anything imported/updated (or an empty batch with no errors); 422 when the whole
  # batch is rejected (bad JSON, or every question failed validation).
  def import_status(result)
    if (result.imported + result.updated).zero? && result.errors.any?
      :unprocessable_content
    else
      :ok
    end
  end

  def authenticate_token!
    return if valid_token?

    render json: { errors: ['Unauthorized'] }, status: :unauthorized
  end

  def valid_token?
    expected = import_api_token
    return false if expected.blank?

    provided = request.authorization.to_s.remove(/\ABearer\s+/i)
    ActiveSupport::SecurityUtils.secure_compare(provided, expected)
  end

  def import_api_token
    Rails.application.credentials.dig(:import_api, :token).presence || ENV['IMPORT_API_TOKEN'].presence
  end
end
