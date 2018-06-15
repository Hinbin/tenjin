class SessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_session, only: [:show]

  # GET /questions
  # GET /questions.json
  def index
    @sessions = Session.all
  end

  def show
  end

  def new
    @session = Session.new
  end

  def create
    @session = Session.new
    @session.user_id = current_user.id
    @session.timeAsked = DateTime.now
    @session.streak = 0
    @session.answeredCorrect = 0
    @session.numQuestionsAsked = 0

    respond_to do |format|
      @session.start!
      if @session.save
        format.html { redirect_to @session, notice: 'Session was successfully created.' }
        format.json { render :show, status: :created, location: @session }
      else
        format.html { render :new }
        format.json { render json: @session.errors, status: :unprocessable_entity }
      end
    end
  end 

  private
    def set_session
        @session = Session.find(params[:id])
    end

end