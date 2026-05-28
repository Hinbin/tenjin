import { saveQuestionText } from "../../../app/javascript/app/questions";

describe("saveQuestionText", () => {
  beforeEach(() => {
    document.body.innerHTML =
      '<input id="question_question_text" value="What is 2+2?" />';
    jest.spyOn($, "ajax").mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
    document.body.innerHTML = "";
  });

  it("does not invoke the callback immediately when called", () => {
    const callback = jest.fn();
    saveQuestionText(callback, "/questions/1");
    expect(callback).not.toHaveBeenCalled();
  });

  it("passes the callback as the ajax success handler so it fires on completion", () => {
    const callback = jest.fn();
    saveQuestionText(callback, "/questions/1");

    const ajaxOptions = $.ajax.mock.calls[0][0];

    expect(typeof ajaxOptions.success).toBe("function");

    ajaxOptions.success();
    expect(callback).toHaveBeenCalledTimes(1);
  });
});
