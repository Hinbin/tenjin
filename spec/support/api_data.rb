require 'rails_helper'

RSpec.shared_context 'api_data', shared_context: :metadata do
  let(:school_api_data) { School.from_wonde(OpenStruct.new(id: '1234', name: 'test'), 'token') }
  let(:user_api_data) do
    OpenStruct.new(data: [OpenStruct.new(id: '01234', upi: '01234',
                                         forename: 'TestForename', surname: 'TestSurname')])
  end
  let(:alt_user_api_data) do
    OpenStruct.new(data: [OpenStruct.new(id: '56789', upi: '56789',
                                         forename: 'TestForename', surname: 'TestSurname')])
  end
  let(:subject_api_data) do
    OpenStruct.new(data: OpenStruct.new(id: 'sub1234', name: 'Computer Science'))
  end
  let(:classroom_api_data) do
    [OpenStruct.new(id: '5678', subject: subject_api_data, code: 'CS')]
  end

end
