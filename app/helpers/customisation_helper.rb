# frozen_string_literal: true

module CustomisationHelper
  def customisation_cost(style)
    return '0' if @bought_customisations.include? style.id

    style.cost.to_s
  end
end
