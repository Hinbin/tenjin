class SessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_session, only: [:show, :update]
    before_action :set_question, only: [:show, :update]

  # GET /questions
  # GET /questions.json
  def index
    @sessions = Session.all
  end

  def show
    @questionNumber = @session.getQuestion 
  end

  def update

    unless ( params.dig(:question, :answer_ids).blank? )
      @session.nextQuestion!
      check_correct_answer(params[:question][:answer_ids])
    else
      redirect_to action: 'show'
    end

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

    def set_question
      @questionNumber = @session.getQuestion 
      @question = Question.find_by(id: @questionNumber)
    end

    def check_correct_answer(answerID)

      @answerGiven = Answer.find_by( id: answerID )

      if @answerGiven.correct
        @session.answeredCorrect = @session.answeredCorrect + 1
        @session.streak = @session.streak + 1
      else
        @session.streak = 0
      end
  
      @session.save
  
      if (@session.numQuestionsAsked >= @session.questionsAsked_id.length)
        @session.endSession!
        redirect_to action: 'new'
      else
        redirect_to action: 'show'
      end
    end

end