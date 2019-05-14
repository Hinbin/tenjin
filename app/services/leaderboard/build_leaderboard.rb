# rubocop:disable Metrics/AbcSize
class Leaderboard::BuildLeaderboard
  def initialize(user, params)
    @user = user
    @subject = Subject.where(name: params.dig(:id)).first
    @topic = params.dig(:topic)
    @school_group = true if @user.school.school_group_id.present? && params.dig(:school_group) == 'true'
    @all_time = true if params.dig(:all_time) == 'true'
  end

  def call
    @query = base_query(topic_scores)
    all_time_query if @all_time
    User.find_by_sql(@query.to_sql)
  end

  def all_time_query
    @query = Arel::Table.new('results').project('results.id',
                                                'results.name',
                                                'results.school_name',
                                                'SUM(results.score) as "score"')
                        .from(Arel::Nodes::TableAlias.new(@query.union(base_query(all_time_topic_scores)), :results))
    @query = @query.group('results.id, results.name, results.school_name')
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

  def active_customisations
    ActiveCustomisation.arel_table
  end

  def customisations
    Customisation.arel_table
  end

  def name
    separator = Arel::Nodes.build_quoted(' ')

    Arel::Nodes::NamedFunction.new(
      'concat',
      [users[:forename], separator, Arel::Nodes::NamedFunction.new('LEFT', [users[:surname], 1])]
    ).as('name')
  end

  def base_query(topic_table)
    @query = users.project(users[:id],
                           name,
                           schools[:name].as('school_name'),
                           topic_table[:score].sum.as('score'),
                           leaderboard_icon_subquery[:value].as('icon'))
    users_and_schools
    @query = @query.join(topic_table).on(users[:id].eq(topic_table[:user_id]))
    @query = @query.join(topics).on(topics[:id].eq(topic_table[:topic_id]))
    join_leaderboard_icons
    @school_group ? by_school_group : by_school
    @topic.present? ? by_topic : by_subject
  end

  def join_leaderboard_icons
    @query = @query.join(leaderboard_icon_subquery, Arel::Nodes::OuterJoin)
                   .on(leaderboard_icon_subquery[:user_id].eq(users[:id]))
    @query.group('n1.value')
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
    @query = @query.where(topics[:id].eq(@topic))
  end

  def by_subject
    @query = @query.where(topics[:subject_id].eq(@subject.id))
  end

  def leaderboard_icon_subquery
    active_customisations.project(active_customisations[:user_id], customisations[:value])
                         .join(customisations).on(active_customisations[:customisation_id].eq(customisations[:id]))
                         .where(customisations[:customisation_type].eq('leaderboard_icon'))
                         .as('n1')
  end
end

# rubocop:enable Metrics/AbcSize
