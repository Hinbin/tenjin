class Leaderboard::BuildLeaderboard
  def initialize(user, subject, topic, params)
    @user = user
    @subject = subject
    @topic = topic
    @query = base_query
    @school_group = true if @user.school.school_group_id.present? && params.dig(:school_group) == "true"
    @all_time = true if params.dig(:all_time) == "true"
  end

  def ts
    TopicScore.arel_table
  end

  def users
    User.arel_table
  end

  def topics
    Topic.arel_table
  end

  def schools
    School.arel_table
  end

  def base_query
    @query = ts.project(ts[:user_id], users[:forename], Arel.sql('left (surname, 1) as surname'), schools[:name].as('school_name'),
                        ts[:score].sum.as('score'),
                        Arel.sql('row_number() OVER (ORDER by SUM(score) DESC, users.forename) as rank'))
    @query = @query.join(users).on(users[:id].eq(ts[:user_id]))
    @query = @query.join(schools).on(schools[:id].eq(users[:school_id]))
    @query = @query.group('user_id', 'users.forename', 'users.surname', 'schools.name')
  end

  def by_school
    @query = @query.where(users[:school_id].eq(@user.school_id))
  end

  def by_school_group
    @query = @query.where(schools[:school_group_id].eq(@user.school.school_group_id))
  end

  def by_topic
    @query = @query.where(ts[:topic_id].eq(@topic.id))
  end

  def by_subject
    @query = @query.join(topics).on(topics[:id].eq(ts[:topic_id]))
    @query = @query.where(topics[:subject_id].eq(@subject.id))
  end

  def call
    @school_group ? by_school_group : by_school
    @topic.present? ? by_topic : by_subject
    TopicScore.find_by_sql(@query.to_sql)
  end
end
