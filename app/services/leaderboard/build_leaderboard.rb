class Leaderboard::BuildLeaderboard
  def initialize(user, subject, topic, window: 50)
    @user = user
    @subject = subject
    @topic = topic
    @query = base_query
    @window = window
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
    @query = ts.project(ts[:user_id], users[:forename], users[:surname], schools[:name].as('school_name'),
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

  def rank
    rank_position = Arel::Table.new(:rank_position)
    rank_as = Arel::Nodes::As.new(rank_position, @query)
    rank_query = rank_position.project(rank_position[:rank]).with(rank_as).where(rank_position[:user_id].eq(@user.id))
    rank_results = TopicScore.find_by_sql(rank_query.to_sql)

    return @window / 2 unless rank_results.count.positive?

    user_rank = rank_results.first.rank
    user_rank < (@window / 2) ? @window / 2 : user_rank
  end

  def call
    @user.school.school_group_id.blank? ? by_school : by_school_group
    @topic.present? ? by_topic : by_subject
    user_rank = rank
    @query.take(@window).skip(user_rank - (@window / 2))
    TopicScore.find_by_sql(@query.to_sql)
  end
end
