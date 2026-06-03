# frozen_string_literal: true

require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Leaderboard::BuildLeaderboard, :default_creates do
  before do
    create(:enrollment, classroom: classroom, user: student)
    create(:topic_score, topic: topic, user: student)
  end

  let(:student) { create(:student, forename: 'Aaaron', school: school) } # Ensure first alphabetically
  let(:topic_different_subject) { create(:topic) }
  let(:topic_same_subject) { create(:topic, subject: subject) }
  let(:school) { create(:school, school_group: nil) }
  let(:second_student) { create(:student, school: school) }

  context 'when returning student data' do
    let(:call) { described_class.new(student, id: subject.name).call.first } # Issue with subject() Using let instead.
    let(:leaderboard_icon) { create(:customisation, customisation_type: 'leaderboard_icon') }

    it 'includes the school name' do
      expect(call.school_name).to eq(school.name)
    end

    it 'includes the first name and last initial of the student' do
      expect(call.name).to eq("#{student.forename} #{student.surname.first}")
    end

    it 'includes a leaderboard icon if it is active for the user' do
      create(:active_customisation, user: student, customisation: leaderboard_icon)
      expect(call.icon).to eq(leaderboard_icon.value)
    end

    it 'includes a leaderboard icon if it is active for others' do
      create(:active_customisation, user: second_student, customisation: leaderboard_icon)
      create(:topic_score, topic: topic, user: second_student)
      expect(described_class.new(student, id: subject.name).call
                            .find { |user| user['id'] == second_student.id }.icon).to eq(leaderboard_icon.value)
    end

    it 'does not include a leaderboard icon for those that do not have one' do
      create(:topic_score, topic: topic, user: second_student)
      expect(described_class.new(student, id: subject.name).call
                            .find { |user| user['id'] == second_student.id }.icon).to eq(nil)
    end
  end

  context 'when building a subject leaderboard' do
    let(:call) { described_class.new(student, id: subject.name).call }

    it 'shows students from the correct subject' do
      create(:topic_score, topic: topic, school: school, score: 10)
      expect(call.count).to eq(2)
    end

    it 'does not show students from other topics' do
      create(:topic_score, topic: topic_different_subject, school: school, score: 10)
      expect(call.count).to eq(1)
    end

    it 'includes the score for the subject' do
      create(:topic_score, user: student, topic: topic_same_subject, school: school)
      expect(call.first.score).to eq(TopicScore.all.sum(:score))
    end
  end

  context 'when buildling a topic leaderboard' do
    let(:call) { described_class.new(student, id: subject.name, topic: topic.id).call }

    it 'shows students from the same topic' do
      create(:topic_score, topic: topic, school: school, score: 10)
      expect(call.count).to eq(2)
    end

    it 'does not show students from another topic' do
      create(:topic_score, topic: topic_same_subject, school: school)
      expect(call.count).to eq(1)
    end

    it 'includes the score for the topic only' do
      create(:topic_score, topic: topic_same_subject, school: school)
      expect(call.first.score).to eq(TopicScore.first.score)
    end
  end

  context 'when building a leaderboard for a single school' do
    let(:call) { described_class.new(student, id: subject.name, topic: topic.id).call }
    let(:different_school) { create(:school) }

    it 'shows students from that school' do
      create(:topic_score, topic: topic, school: school)
      expect(call.count).to eq(2)
    end

    it 'does not show students from a different school' do
      create(:topic_score, topic: topic, school: different_school)
      expect(call.count).to eq(1)
    end
  end

  context 'when building a leaderboard for a school group' do
    let(:school) { create(:school) }
    let(:school_different_school_group) { create(:school) }
    let(:student_no_school_group) { create(:student, school: school_without_school_group) }
    let(:call) { described_class.new(student, id: subject.name, school_group: 'true').call }

    it 'does not show students who belong to a different school group' do
      create(:topic_score, topic: topic, school: school_different_school_group)
      expect(call.count).to eq(1)
    end

    it 'shows students who belong to the same school group' do
      create(:topic_score, topic: topic, school: second_school)
      expect(call.count).to eq(2)
    end

    it 'does not show students who do not belong to any school group' do
      create(:topic_score, topic: topic, user: student_no_school_group)
      expect(call.count).to eq(1)
    end
  end

  context 'when building an all time leaderboard' do
    let(:call) { described_class.new(student, id: subject.name, all_time: 'true').call }

    it 'takes data from the all time topic scores' do
      create(:all_time_topic_score, user: student, topic: topic)
      expect(call.first.score).to eq(AllTimeTopicScore.all.sum(:score))
    end
  end
end
