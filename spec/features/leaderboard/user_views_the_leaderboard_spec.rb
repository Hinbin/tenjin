# frozen_string_literal: true

require 'rails_helper'
require 'support/api_data'
require 'pry'

RSpec.describe 'User views the leaderboard', type: :feature, js: true do
  include_context 'default_creates'

  let(:topic_score) { create(:topic_score, topic: topic, user: student) }
  let(:student) { create(:student, forename: 'Aaaron', school: school) } # Ensure first alphabetically
  let(:student_name) { initialize_name student }
  let(:another_name) { initialize_name User.second }
  let(:one_to_ten) do
    (1..10).each do |n|
      create(:topic_score, topic: topic, school: school, score: n)
    end
  end
  let(:one_to_nine) do
    (1..9).each do |n|
      create(:topic_score, topic: topic, school: school, score: n)
    end
  end

  before do
    setup_subject_database
    sign_in student
    topic_score
  end

  it 'displays myself if I have a score' do
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('td', exact_text: student_name)
  end

  it 'puts the scores in order' do
    TopicScore.first.update(score: 5)
    student.update(forename: 'Aaron') # Ensure first alphabetically
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('tr:nth-child(6)', text: student_name)
  end

  it 'displays others if they have a score' do
    create_list(:topic_score, 8, topic: topic, school: school)
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('td', exact_text: another_name)
  end

  it 'shows me what position I am in within the school' do
    TopicScore.first.update(score: 5)
    student.update(forename: 'Aaron') # Ensure first alphabetically
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('tr', text: ('6 ' + student_name).to_s)
  end

  it 'does not show students from another school' do
    create(:topic_score, topic: topic)
    visit(leaderboard_path(subject.name))
    expect(page).to have_no_css('td', exact_text: another_name)
  end

  it 'defaults to show 10 entries' do
    TopicScore.first.update(score: 5)
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('table#leaderboardTable tr', count: 11)
  end

  it 'shows the top 10 if I have no score' do
    TopicScore.first.destroy
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('tr:nth-child(10) td', exact_text: '10')
  end

  it 'shows me when I am at the top of the table' do
    TopicScore.first.update(score: 50)
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('table#leaderboardTable tr', count: 11)
  end

  it 'shows me when I am at the bottom of the table' do
    TopicScore.first.update(score: 0)
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('tr:nth-child(10) td:nth-child(6)', text: TopicScore.first.score)
  end

  it 'shows others when I am near the bottom of the table' do # bug
    TopicScore.first.update(score: 3)
    one_to_ten
    visit(leaderboard_path(subject.name))
    expect(page).to have_css('tr:nth-child(8) td:nth-child(3)', text: student.forename)
  end

  it 'hides schools on a small screen' do
    size = page.driver.browser.manage.window.size
    visit(leaderboard_path(subject.name))
    page.driver.browser.manage.window.resize_to(375, 667)
    expect(page).to have_no_css('td', exact_text: school.name)
    page.driver.browser.manage.window.resize_to(size.width, size.height)
  end

  context 'when viewing leaderboard icons' do
    let(:blue_star) do
      create(:customisation, customisation_type: 'leaderboard_icon',
                             value: 'blue,star', name: 'Blue Star')
    end

    let(:pink_star) do
      create(:customisation, customisation_type: 'leaderboard_icon',
                             value: 'pink,star', name: 'Pink Star')
    end

    before do
      create(:active_customisation, user: student, customisation: blue_star)
      one_to_ten
    end

    it 'shows the leaderboard icon for a person' do
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: blue;')
    end

    it 'shows a blank space if there is no leaderboard icon' do
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td')
    end

    it 'shows different colours of leaderboard icons' do
      ActiveCustomisation.destroy_all
      create(:active_customisation, user: student, customisation: pink_star)
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: pink;')
    end
  end

  context 'when viewing a subjects overall score' do
    let(:second_topic_score) { create(:topic_score, user: student, topic: create(:topic, subject: Subject.first)) }
    let(:second_subject_score) { create(:topic_score, user: student, topic: create(:topic)) }
    let(:overall_total) { TopicScore.first.score + TopicScore.second.score }

    it 'adds up scores from different topics' do
      second_topic_score
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr.current-user td:nth-child(4)', exact_text: overall_total)
    end

    it 'ignores scores from topics of a different subject' do
      second_subject_score
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr.current-user td:nth-child(4)', exact_text: TopicScore.first.score)
    end
  end

  context 'when viewing weekly awards' do
    let(:second_award) do
      create(:leaderboard_award,
             user: TopicScore.all.second.user,
             subject: TopicScore.all.second.subject,
             school: TopicScore.all.second.user.school)
    end

    before do
      create(:leaderboard_award, user: topic_score.user, subject: topic_score.subject, school: topic_score.user.school)
    end

    it 'shows a star for a weekly award' do
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: red;')
    end

    it 'shows a gold star for 5 or more wins' do
      create_list(:leaderboard_award, 5, user: topic_score.user, subject: topic_score.subject, school: topic_score.user.school)
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: gold;')
    end
    it 'shows a silver star for 3 or more wins' do
      create_list(:leaderboard_award, 2, user: topic_score.user, subject: topic_score.subject, school: topic_score.user.school)
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: silver;')
    end

    it 'shows stars for more than one user' do
      one_to_nine
      second_award
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('td i.fa-star', style: 'color: red;', count: 2)
    end
  end

  context 'when showing weekly winners' do
    it 'shows last weeks winner for the classroom' do
      create(:classroom_winner, user: student, classroom: classroom, score: 100)
      visit(leaderboard_path(subject.name))
      click_button('Select Class')
      click_button(classroom.name)
      expect(page).to have_content("#{classroom.name} winner: #{student.forename}")
    end
  end
end
