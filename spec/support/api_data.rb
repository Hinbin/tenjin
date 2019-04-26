require 'rails_helper'

RSpec.shared_context 'api_data', shared_context: :metadata do
  let(:school_api_data) do
    School.from_wonde(OpenStruct.new(id: SecureRandom.hex, name: FFaker::Education.school), SecureRandom.hex)
  end
  let(:user_api_data) do
    OpenStruct.new(data: [OpenStruct.new(id: SecureRandom.hex, upi: SecureRandom.hex,
                                         forename: FFaker::Name.first_name, surname: FFaker::Name.last_name)])
  end
  let(:alt_user_api_data) do
    OpenStruct.new(data: [OpenStruct.new(id: SecureRandom.hex, upi: SecureRandom.hex,
                                         forename: FFaker::Name.first_name, surname: FFaker::Name.last_name)])
  end
  let(:subject_api_data) do
    OpenStruct.new(data: OpenStruct.new(id: SecureRandom.hex, name: FFaker::Lorem.word))
  end
  let(:classroom_api_data) do
    [OpenStruct.new(id: SecureRandom.hex, subject: subject_api_data, code: FFaker::Lorem.word)]
  end
end

RSpec.shared_context 'wonde_test_data', shared_context: :metadata do
  let(:school_token) { '2a550dc912f6a63488af42352b79c5961e87daf9' }
  let(:school_id) { 'A852030759' }
  let(:school_name) { 'Outwood Grange Academy 1532082212' }
  let(:school_params) { ActionController::Parameters.new(token: school_token, client_id: school_id) }
  let(:school) do
    create(:school, client_id: school_id, name: school_name,
                    token: school_token, sync_status: 'successful', permitted: true)
  end

  let(:subject_to_map) { 'Sociology' }
  let(:default_subject_map) { create(:default_subject_map, name: subject_to_map) }

  let(:classroom_client_id) { 'A1906124304' }
  let(:classroom_name) { 'SOC 2' }

  let(:student_upi) { '1479cf1d289684f08600c9ad1f6406fc' }
  let(:student_forename) { 'Leo' }
  let(:student_wonde) { create(:user, forename: student_forename, surname: 'Ward', upi: student_upi, school: school) }

  let(:employee_upi) { 'caea4baa5b7adac73ab1259987d2bcc0' }
  let(:employee_name) { 'Emma' }
end
