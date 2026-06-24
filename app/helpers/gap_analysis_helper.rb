# frozen_string_literal: true

# Presentation helpers for the difficulty-aware, cohort-relative gap-analysis surfaces
# (classrooms#gaps / #student_gap). Pure view formatting over Analytics::ClassGapReport /
# Analytics::StudentGapReport payloads — no data access of its own.
module GapAnalysisHelper
  # A metric-card label with a hover tooltip explaining the term. The trailing ⓘ marker reveals the
  # explanation via a CSS tooltip (data-tooltip drives the ::after bubble) and native title. It is
  # decorative (aria-hidden, not focusable) because the cards are anchor links — a focusable element
  # nested inside a link is invalid HTML — so the explanation is mouse-hover sugar over the visible
  # label, not load-bearing.
  def gap_card_label(text, explanation)
    tag.span(class: 'tj-gap-card-label') do
      safe_join([text, ' ',
                 tag.span('ⓘ', class: 'tj-gap-info', 'aria-hidden': true,
                               'data-tooltip': explanation, title: explanation)])
    end
  end

  # A 0..1 score as a whole-number percentage; em dash for "no data" (nil).
  def gap_percent(score)
    return '—' if score.nil?

    number_to_percentage(score * 100, precision: 0)
  end

  # Difficulty band as a coloured chip (easy/medium/hard from Analytics::QuestionDifficulty).
  def difficulty_band_chip(band)
    return '' if band.nil?

    tag.span(band.to_s.capitalize, class: "tj-gap-band tj-gap-band--#{band}")
  end

  # Cohort standing as a coloured chip (above / on_par / below / unknown).
  def standing_chip(standing)
    labels = { above: 'Above average', on_par: 'On par', below: 'Below average', unknown: 'No data' }
    tag.span(labels.fetch(standing, 'No data'), class: "tj-gap-standing tj-gap-standing--#{standing}")
  end

  # The whole class-vs-cohort comparison folded into one figure: a directional arrow plus the size of
  # the gap in percentage points (e.g. ↑ 8%). Replaces the separate class-mastery / cohort-baseline /
  # standing cards — the underlying numbers live in the tooltip (standing_tooltip). `overall` is
  # @report.cohort_comparison[:overall].
  def standing_delta(overall)
    delta = overall[:delta]
    return tag.span('—', class: 'tj-gap-card-value tj-gap-delta tj-gap-delta--unknown') if delta.nil?

    standing = overall[:standing]
    points = number_to_percentage(delta.abs * 100, precision: 0)
    tag.span(standing_delta_parts(standing, points),
             class: "tj-gap-card-value tj-gap-delta tj-gap-delta--#{standing}",
             'aria-label': standing_delta_aria(standing, points))
  end

  # The arrow + percentage spans inside the combined standing figure.
  def standing_delta_parts(standing, points)
    safe_join([tag.span(standing_arrow(standing), class: 'tj-gap-delta-arrow', 'aria-hidden': true),
               tag.span(points, class: 'tj-gap-delta-pct')])
  end

  # Directional glyph for the combined standing figure.
  def standing_arrow(standing)
    { above: '↑', below: '↓', on_par: '→' }.fetch(standing, '–')
  end

  # Tooltip for the combined standing card: spells out the class and cohort figures the arrow distils.
  def standing_tooltip(overall)
    return 'Not enough shared activity to compare this class against the cohort yet.' if overall[:delta].nil?

    "Difficulty-weighted. This class averages #{gap_percent(overall[:mastery])} on the questions " \
      "they've attempted, against #{gap_percent(overall[:cohort_mastery])} for all Tenjin students on " \
      'the same questions.'
  end

  # Screen-reader text for the combined standing figure (the arrow itself is aria-hidden).
  def standing_delta_aria(standing, points)
    { above: "#{points} above the cohort baseline", below: "#{points} below the cohort baseline",
      on_par: 'On par with the cohort baseline' }.fetch(standing, 'No data')
  end

  # Heatmap cell tint: low mean score => hot (red), high => cool (green). Drives the student gap
  # heatmaps. The background is always a light pastel, so pin a dark ink — the skin's default table
  # colour is near-white (--ink) and would vanish against it.
  def heat_style(score)
    hue = (score.to_f * 120).round # 0 = red, 120 = green
    "background:hsl(#{hue},70%,88%);color:#1a1a1a"
  end

  # Diverging tint for a topic's standing against the cohort: below cohort => warm (red), above =>
  # cool (green), on par => near-neutral, no comparison (nil delta) => flat grey. `delta` is the
  # difficulty-weighted gap (own minus cohort, roughly -1..1). Magnitude drives saturation so a wide
  # gap reads stronger than a slim one, capped at a 25-point gap. Dark ink pinned for the same reason
  # as heat_style — the pale tints would swallow the skin's near-white default.
  def standing_heat_style(delta)
    return 'background:#f1f1f1;color:#6c757d' if delta.nil?

    hue = delta.negative? ? 0 : 130 # red below cohort, green above
    saturation = (12 + ([delta.abs, 0.25].min / 0.25 * 58)).round # 12%..70%
    "background:hsl(#{hue},#{saturation}%,90%);color:#1a1a1a"
  end

  # The per-cell standing line in the topic gap grid: a coloured arrow + the size of the gap against
  # the cohort (e.g. "↑ 8% vs cohort"), or a plain label when the class is on par or there is not yet
  # any cohort data to compare against. Mirrors standing_chip's vocabulary in heatmap form.
  def topic_standing_line(row)
    standing = row[:standing]
    return standing_line_label('No cohort data yet', :unknown) if row[:delta].nil?
    return standing_line_label('On par with cohort', :on_par) if standing == :on_par

    points = number_to_percentage(row[:delta].abs * 100, precision: 0)
    label = safe_join([tag.span(standing_arrow(standing), 'aria-hidden': true), " #{points} vs cohort"])
    standing_line_label(label, standing)
  end

  def standing_line_label(text, standing)
    tag.span(text, class: "tj-gap-heat-standing tj-gap-heat-standing--#{standing}")
  end

  # A lesson drill-down row: the lesson name over a full-width track whose fill is the class's
  # difficulty-weighted score, coloured by standing (green above cohort, red below) with a tick marking
  # where the cohort sits. `topic_name` drops the redundant topic prefix the lesson records carry
  # ("1-3 Storage: Going deeper" -> "Going deeper"). Plain "no data" line when there's no activity yet.
  def lesson_gap_bar(row, topic_name = nil)
    name = lesson_short_name(row[:lesson_name], topic_name)
    return lesson_gap_bar_empty(name) if row[:mastery].nil?

    tag.div(lesson_gap_bar_cells(row, name), class: 'tj-gap-lesson',
                                             'aria-label': lesson_gap_bar_aria(row, name))
  end

  # Lesson name over a bar row (track + percentage), the two stacked parts of a lesson row.
  def lesson_gap_bar_cells(row, name)
    bar = safe_join([lesson_gap_track(row), tag.span(gap_percent(row[:mastery]), class: 'tj-gap-lesson-score')])
    safe_join([tag.span(name, class: 'tj-gap-lesson-name'), tag.div(bar, class: 'tj-gap-lesson-bar')])
  end

  # The bar itself: a full-width track holding the class-score fill (coloured by standing) and a cohort
  # tick that floats where the cohort sits — omitted when there's no cohort figure. Inline width/left
  # are pure data, not style.
  def lesson_gap_track(row)
    standing = row[:standing] || :on_par
    fill = tag.span(class: "tj-gap-lesson-fill tj-gap-lesson-fill--#{standing}",
                    style: "width:#{(row[:mastery].to_f * 100).round}%")
    cohort = row[:cohort_mastery]
    tick = cohort && tag.span(class: 'tj-gap-lesson-tick', title: "Cohort #{gap_percent(cohort)}",
                              style: "left:#{(cohort * 100).round}%")
    tag.span(safe_join([fill, tick]), class: 'tj-gap-lesson-track')
  end

  # Strip the redundant topic prefix lesson records carry ("<topic>: <lesson>"); keep the full name if
  # stripping would leave nothing (e.g. a lesson named exactly after its topic).
  def lesson_short_name(name, topic_name)
    return name if name.blank? || topic_name.blank?

    name.sub(/\A#{Regexp.escape(topic_name)}\s*[:–—-]\s*/, '').presence || name
  end

  # Plain fallback when a lesson has no class activity to draw a bar from.
  def lesson_gap_bar_empty(name)
    tag.div(class: 'tj-gap-lesson tj-gap-lesson--empty') do
      safe_join([tag.span(name, class: 'tj-gap-lesson-name'),
                 tag.span('No data yet', class: 'tj-gap-heat-standing tj-gap-heat-standing--unknown')])
    end
  end

  # Screen-reader summary for a lesson bar — the colour and tick are visual-only.
  def lesson_gap_bar_aria(row, name)
    cohort = row[:cohort_mastery] && ", cohort #{gap_percent(row[:cohort_mastery])}"
    "#{name}: class #{gap_percent(row[:mastery])}#{cohort}"
  end
end
