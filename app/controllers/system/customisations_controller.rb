# frozen_string_literal: true

module System
  class CustomisationsController < BaseController
    def index
      authorize Customisation, :index?
      @customisations = policy_scope(Customisation).where(retired: false).with_attached_image
      @retired_customisations = policy_scope(Customisation).where(retired: true).with_attached_image
    end

    def new
      @customisation = Customisation.new(purchasable: false, retired: false)
      authorize @customisation
      render :edit
    end

    def edit
      @customisation = authorize find_customisation
    end

    def create
      @customisation = Customisation.new(customisation_params)
      authorize @customisation

      if @customisation.save
        redirect_to system_customisations_path, notice: "Created new customisation #{@customisation.name}"
      else
        render :edit
      end
    end

    def update
      customisation = authorize find_customisation
      customisation.update(customisation_params)
      redirect_to system_customisations_path
    end

    private

    def find_customisation
      Customisation.find(params[:id])
    end

    def customisation_params
      params.require(:customisation).permit(:name, :value, :purchasable, :sticky, :image, :customisation_type, :cost, :retired)
    end
  end
end
