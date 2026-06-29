# frozen_string_literal: true

# Recomputes every student's percentile standing per topic from AllTimeTopicScore in a single SQL
# pass and upserts it into topic_percentiles. Run as part of the weekly leaderboard reset, *after*
# this week's points have been folded into the all-time scores and *before* the weekly tables are
# wiped, so percentiles reflect the just-closed week.
#
# cume_dist() gives, for each row, the fraction of peers in that topic scoring at or below them — i.e.
# "you are ahead of N% of students". Note: a topic where every student has the same score (e.g. all 0)
# resolves to the 100th percentile for everyone; that washes out as soon as any spread exists.
class Leaderboard::ComputeTopicPercentiles < ApplicationService
  def call
    ActiveRecord::Base.connection.exec_query(upsert_sql)
  end

  protected

  def upsert_sql
    <<~SQL.squish
      INSERT INTO topic_percentiles (user_id, topic_id, percentile, created_at, updated_at)
      SELECT user_id,
             topic_id,
             ROUND(cume_dist() OVER (PARTITION BY topic_id ORDER BY score) * 100)::int,
             NOW(),
             NOW()
      FROM all_time_topic_scores
      ON CONFLICT (user_id, topic_id)
      DO UPDATE SET percentile = EXCLUDED.percentile, updated_at = NOW()
    SQL
  end
end
