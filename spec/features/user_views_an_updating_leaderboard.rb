require 'rails_helper'
require 'support/api_data'
require 'pry'

RSpec.describe 'User views an updating leaderboard', type: :feature, js: true do
  include_context 'default_creates'

  before do
    setup_subject_database
    sign_in student
    create(:quiz, topic: topic, user: student)
    visit(leaderboard_path(subject.name))
  end

  let(:student_name) { initialize_name student }
  let(:another_name) { initialize_name User.second }
  let(:one_to_ten) do
    (1..10).each do |n|
      create(:topic_score, topic: topic, school: school, score: n)
    end
  end
  let(:add_point) do
    @quiz = params[:quiz]
    @question = params[:question]
  end

  it 'flashes an update if another person has a score' do
    update_score
  end
  it 'does not update if update is from an unaffiliated school'
  it 'does update if score is from the same school group'
  it 'works when there is no school group'
  it 'only updates the current subject'
  it 'flashes me when I have a score'
  it 'can handle receiving two scores at the same time'
  it 'only flashes once, for a second'
  it 'handles a new student having a score'
  it 're-ranks correctly'


  context 'when viewing a single topic' do
    it 'only updates the current topic'
  end
  
  it 'displays myself if I have a score' do

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
    expect(page).to have_css('tr:nth-child(10) td:nth-child(4)', text: TopicScore.first.score)
  end

  it 'hides schools on a small screen' do
    size = page.driver.browser.manage.window.size
    visit(leaderboard_path(subject.name))
    page.driver.browser.manage.window.resize_to(375, 667)
    expect(page).to have_no_css('td', exact_text: school.name)
    page.driver.browser.manage.window.resize_to(size.width, size.height)
  end

  context 'when viewing a subjects overall score' do
    let(:second_topic_score) { create(:topic_score, user: student, topic: create(:topic, subject: Subject.first)) }
    let(:second_subject_score) { create(:topic_score, user: student, topic: create(:topic)) }
    let(:overall_total) { TopicScore.first.score + TopicScore.second.score }

    it 'adds up scores from different topics' do
      second_topic_score
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr.bg-dark td:nth-child(4)', exact_text: overall_total)
    end

    it 'ignores scores from topics of a different subject' do
      second_subject_score
      visit(leaderboard_path(subject.name))
      expect(page).to have_css('tr.bg-dark td:nth-child(4)', exact_text: TopicScore.first.score)
    end
  end
end
