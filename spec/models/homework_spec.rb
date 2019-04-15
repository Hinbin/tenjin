require 'rails_helper'
require 'support/session_helpers'

RSpec.describe Homework, type: :model do

  let(:homework) { create( :homework, classroom: classroom )}
  let(:homework_old) { build( :homework, classroom: classroom, topic: topic, due_date: DateTime.now - 1.day )}

  before do
    create(:enrollment, classroom: classroom, user: student)
  end
  context 'when dealing with homework progress', default_creates: :true do

    it 'deletes user progresses after being destroyed' do
      expect{homework}.to change(HomeworkProgress, :count).by (1) 
    end
  
    it 'does not create a user progress for a non-student' do
      create(:enrollment, classroom: classroom, user: teacher)
      expect{homework}.to change(HomeworkProgress, :count).by (1) 
    end
  
    it 'deletes user progresses after being destroyed' do
      homework
      expect{homework.destroy}.to change(HomeworkProgress, :count).by (-1) 
    end

  end

  context 'when creating a homework', default_creates: :true do 
    it 'does not let you create a homework with a due date in the past' do
      expect{homework_old.save!}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end


end
