class Leaderboard::BuildLeaderboard
  def initialize(user, subject, topic, params)
    @user = user
    @subject = subject
    @topic = topic
    @school_group = true if @user.school.school_group_id.present? && params.dig(:school_group) == 'true'
    @all_time = true if params.dig(:all_time) == 'true'
  end

  def topic_scores
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

  def all_time_topic_scores
    AllTimeTopicScore.arel_table
  end

  def surname_initial
    Arel::Nodes::NamedFunction.new('LEFT', [users[:surname], 1]).as('surname')
  end

  def base_query(topic_table)
    @query = users.project(users[:id],
                           users[:forename],
                           surname_initial,
                           schools[:name].as('school_name'),
                           topic_table[:score].sum.as('score'))
    users_and_schools
    @query = @query.join(topic_table).on(users[:id].eq(topic_table[:user_id]))
    @query = @query.join(topics).on(topics[:id].eq(topic_table[:topic_id]))

    @school_group ? by_school_group : by_school
    @topic.present? ? by_topic : by_subject
  end

  def users_and_schools
    @query = @query.join(schools).on(schools[:id].eq(users[:school_id]))
    @query = @query.group('users.id', 'schools.id')
  end

  def by_school
    @query = @query.where(users[:school_id].eq(@user.school_id))
  end

  def by_school_group
    @query = @query.where(schools[:school_group_id].eq(@user.school.school_group_id))
  end

  def by_topic
    @query = @query.where(topics[:id].eq(@topic.id))
  end

  def by_subject
    @query = @query.where(topics[:subject_id].eq(@subject.id))
  end

  def call
    @query = base_query(topic_scores)

    if @all_time
      @query = Arel::Table.new('results').project('results.id',
                                                  'results.forename',
                                                  'results.surname',
                                                  'results.school_name',
                                                  'SUM(results.score) as "score"')
                          .from(Arel::Nodes::TableAlias.new(@query.union(base_query(all_time_topic_scores)), :results))
      @query = @query.group('results.id, results.forename, results.surname, results.school_name')
    end

    User.find_by_sql(@query.to_sql)
  end
end
