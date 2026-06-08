import AutoSubmitController from "../../../app/javascript/controllers/auto_submit_controller";

function makeController(element) {
  return new AutoSubmitController({ scope: { element } });
}

describe("AutoSubmitController#submit", () => {
  let form, controller;

  beforeEach(() => {
    form = document.createElement("form");
    form.action = "/test";
    form.method = "post";
    document.body.appendChild(form);
    controller = makeController(form);
  });

  afterEach(() => {
    document.body.removeChild(form);
  });

  it("calls requestSubmit on the form element", () => {
    const spy = jest.spyOn(form, "requestSubmit").mockImplementation(() => {});
    controller.submit();
    expect(spy).toHaveBeenCalledTimes(1);
  });
});
