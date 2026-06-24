# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'

RSpec.describe User, type: :model do
  describe 'customisation entitlement' do
    let(:school) { create(:school) }
    let(:student) { create(:student, school:) }
    let(:teacher) { create(:teacher, school:) }
    let(:paid_item) { create(:customisation, customisation_type: 'avatar', cost: 50) }

    it 'gives teachers every customisation for free (bypassing the points economy)' do
      expect(teacher.owns_all_customisations?).to be(true)
      expect(teacher.owns?(paid_item)).to be(true)
    end

    it 'leaves students gated on paid items they have not unlocked' do
      expect(student.owns_all_customisations?).to be(false)
      expect(student.owns?(paid_item)).to be(false)
    end

    it 'still treats free items as owned for students' do
      free_item = create(:customisation, customisation_type: 'avatar', cost: 0)
      expect(student.owns?(free_item)).to be(true)
    end
  end

  describe 'cosmetic trial cooldown' do
    let(:student) { create(:student) }

    it 'is available when never trialled' do
      expect(student.cosmetic_trial_available?).to be(true)
      expect(student.cosmetic_trial_available_at).to be_nil
    end

    it 'is unavailable during the cooldown window' do
      started_at = 5.minutes.ago
      student.update!(cosmetic_trial_at: started_at)
      expect(student.cosmetic_trial_available?).to be(false)
      expect(student.cosmetic_trial_available_at)
        .to be_within(1.second).of(started_at + described_class::COSMETIC_TRIAL_COOLDOWN)
    end

    it 'becomes available again once the cooldown has elapsed' do
      student.update!(cosmetic_trial_at: described_class::COSMETIC_TRIAL_COOLDOWN.ago - 1.minute)
      expect(student.cosmetic_trial_available?).to be(true)
    end
  end

  describe '#from_wonde' do
    include_context 'with api_data'

    let(:classroom) { create(:classroom) }

    before do
      school_api_data
    end

    context 'with student api data' do
      it 'does not allow students missing a upi' do
        expect { create(:student, upi: '') }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'creates students who have a classroom for a mapped subject' do
        classroom_api_data.students = user_api_data
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.where(role: 'student').first.forename).to eq(user_api_data.data[0].forename)
      end

      it 'creates employees who have a classroom for a mapped subject' do
        classroom_api_data.employees = user_api_data
        allow(school_api).to receive(:get).and_return(contact_details_api_data)
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.where(role: 'employee').first.forename).to eq(user_api_data.data[0].forename)
      end

      it 'only creates user accounts for those that need them' do
        classroom_data = classroom_api_data
        classroom_data.subject.data.name = 'Not a subject'
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.count).to eq(0)
      end

      it 'accepts both employee and student data' do
        classroom_api_data.students = user_api_data
        classroom_api_data.employees = alt_user_api_data
        allow(school_api).to receive(:get).and_return(contact_details_api_data)
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        expect(described_class.count).to eq(2)
      end

      it 'creates a username for a student' do
        classroom_api_data.students = user_api_data
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        u = user_api_data.data[0]
        expect(described_class.first.username).to eq(u.forename[0].downcase + u.surname.downcase + u.upi[0..3])
      end

      it 'deals with duplicate user names' do
        classroom_api_data.students = duplicate_user_api_data
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        u = duplicate_user_api_data.data[1]
        expect(described_class.second.username)
          .to start_with(u.forename[0].downcase + u.surname.downcase)
      end

      it 'does not update a username if the record already exists' do
        described_class.create(upi: user_api_data.upi, username: 'test')
        classroom_api_data.employees = user_api_data
        allow(school_api).to receive(:get).and_return(contact_details_api_data)
        described_class.from_wonde(school_api_data, classroom_api_data, classroom)
        described_class.first.username = 'test'
      end
    end
  end
end
