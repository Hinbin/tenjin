# frozen_string_literal: true

module QuizzesHelper
  # Per-subject accent token for the quiz chrome (progress bar, topic pill, answer badges). Falls
  # back to the skin's primary neon so every skin × palette stays valid. Self-contained for the
  # quiz surface (Phase 1's dashboard SUBJECT_META is a separate, dashboard-scoped concern).
  SUBJECT_NEON = {
    'Computer Science' => 'var(--n1)',
    'Mathematics' => 'var(--n2)',
    'Science' => 'var(--n3)',
    'English' => 'var(--n2)',
    'History' => 'var(--n3)',
    'Geography' => 'var(--n1)'
  }.freeze

  def render_question
    return render('short_answer') if @question.question_type == 'short_answer'

    render('multiple_choice')
  end

  def subject_neon(subject)
    SUBJECT_NEON.fetch(subject&.name, 'var(--n1)')
  end

  # Results-screen grade band from an accuracy percentage. Mirrors the prototype's S/A/B/C ranks
  # (sk-quiz.jsx ResultsScreen) using skin colour tokens.
  def quiz_rank(accuracy)
    case accuracy
    when 90.. then { grade: 'S', color: 'var(--gold)', jp: '達人', en: 'Master' }
    when 70...90 then { grade: 'A', color: 'var(--n2)', jp: '優秀', en: 'Great' }
    when 50...70 then { grade: 'B', color: 'var(--n3)', jp: '良好', en: 'Good' }
    else { grade: 'C', color: 'var(--n1)', jp: '挑戦', en: 'Keep Going' }
    end
  end
end
