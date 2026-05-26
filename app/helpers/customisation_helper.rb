# frozen_string_literal: true

module CustomisationHelper
  def customisation_cost(style, bought_customisations)
    return if bought_customisations.include? style.id

    safe_join([content_tag(:i, nil, class: "fas fa-star", style: "color: yellow"), style.cost.to_s])
  end
end
