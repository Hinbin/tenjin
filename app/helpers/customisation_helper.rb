# frozen_string_literal: true

module CustomisationHelper
  def customisation_cost(style)
    return if @bought_customisations.include? style.id

    "<i class='fas fa-star' style='color: yellow'></i>#{style.cost}"
  end
end
