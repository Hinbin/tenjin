// The blur listener is registered in capture phase (true) so it catches events on
// child inputs. removeEventListener must pass the same flag — omitting it targets a
// non-existent bubble-phase listener and leaves the capture listener active.

import FormController from "../../../app/javascript/controllers/form_controller";

// Minimal Stimulus v1 context — only needs scope.element to work.
function makeController(element) {
  return new FormController({ scope: { element } });
}

describe("FormController#disconnect", () => {
  let form, input, controller;

  beforeEach(() => {
    form = document.createElement("form");
    input = document.createElement("input");
    input.name = "username";
    input.required = true; // empty value → checkValidity() returns false
    form.appendChild(input);
    document.body.appendChild(form);

    controller = makeController(form);
  });

  afterEach(() => {
    document.body.removeChild(form);
  });

  it("removes the blur listener so validation no longer runs after disconnect", () => {
    controller.connect();
    controller.disconnect();

    // A blur event on a child input should NOT trigger validation after disconnect.
    // With the bug the capture listener is still attached, so 'invalid' IS added.
    input.dispatchEvent(new FocusEvent("blur"));

    expect(input.classList.contains("invalid")).toBe(false);
  });

  it("calls removeEventListener with the capture flag for blur", () => {
    const removeSpy = jest.spyOn(form, "removeEventListener");

    controller.connect();
    controller.disconnect();

    const blurRemovals = removeSpy.mock.calls.filter(
      ([type]) => type === "blur",
    );
    expect(blurRemovals.length).toBeGreaterThan(0);
    blurRemovals.forEach(([, , capture]) => {
      expect(capture).toBe(true);
    });
  });
});
