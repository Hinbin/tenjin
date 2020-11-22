# frozen_string_literal: true

module CustomisationHelper
  def customisation_cost(style)
    return if @bought_customisations.include? style.id

    "<i class='fas fa-star' style='color: yellow'></i>#{style.cost}"
  end

  def customisation_button(style)
    text = if @bought_customisations.include? style.id
             'Switch'
           else
             'Buy'
           end

    classes = if style.customisation_type == 'dashboard_style'
                'btn btn-light-outline float-right buy-btn'
              else
                'btn-block btn-dark-outline buy-btn'
              end

    "<button class='#{classes}' type='submit' data-action='customise#buy'\
    data-customisation-id='#{style.id}' id='buy-#{style.customisation_type}-#{style.value}'>#{text}</button>"
  end
end
