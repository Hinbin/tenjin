# frozen_string_literal: true

class AppErrorsController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_app_error, only: :show

  def index
    authorize AppError
    @app_errors = AppError.order(created_at: :desc).limit(100)
  end

  def show
    authorize @app_error
  end

  private

  def set_app_error
    @app_error = AppError.find(params[:id])
  end
end
