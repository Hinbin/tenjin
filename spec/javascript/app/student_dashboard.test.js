// The click handler is on `.challenge-row` (<tr>). Data attributes live on the
// <tr> itself, so the handler uses event.currentTarget — not event.target, which
// may be a child <td> whose parentNode is <tbody>.

import '../../../app/javascript/app/student_dashboard';

describe('student_dashboard — challenge-row click handler', () => {
  beforeEach(() => {
    jest.spyOn($, 'ajax').mockImplementation(() => {});

    document.body.innerHTML = `
      <table>
        <tbody>
          <tr class="challenge-row"
              data-subject="mathematics"
              data-topic="42"
              data-lesson="7">
            <td>Click me</td>
          </tr>
        </tbody>
      </table>
    `;

    $(document).trigger('turbolinks:load');
  });

  afterEach(() => {
    $(document).off('turbolinks:load');
    jest.restoreAllMocks();
    document.body.innerHTML = '';
  });

  it('reads subject, topic_id, and lesson_id from the <tr> data attributes', () => {
    $('.challenge-row').trigger('click');

    expect($.ajax).toHaveBeenCalled();
    const { data: { quiz } } = $.ajax.mock.calls[0][0];
    expect(quiz.subject).toBe('mathematics');
    expect(quiz.topic_id).toBe(42); // jQuery coerces numeric strings to numbers
    expect(quiz.lesson_id).toBe(7);
  });
});
