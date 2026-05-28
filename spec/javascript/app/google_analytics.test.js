// The GA measurement ID is read from <meta name="google-analytics-id"> (set by the
// Rails layout) rather than inline in the JS, so no ERB processing is needed.

// Import the module — this registers the turbolinks:load listener.
import "../../../app/javascript/app/google_analytics";

describe("google_analytics turbolinks:load handler", () => {
  let mockGtag;

  beforeEach(() => {
    mockGtag = jest.fn();
    global.gtag = mockGtag;
    document.head.innerHTML =
      '<meta name="google-analytics-id" content="G-TEST123">';
  });

  afterEach(() => {
    delete global.gtag;
    document.head.innerHTML = "";
  });

  function fireTurbolinksLoad(url = "https://example.com/page") {
    const event = new Event("turbolinks:load");
    event.data = { url };
    document.dispatchEvent(event);
  }

  it("calls gtag with the GA ID read from the meta tag", () => {
    fireTurbolinksLoad("https://example.com/about");

    expect(mockGtag).toHaveBeenCalledWith("config", "G-TEST123", {
      page_location: "https://example.com/about",
    });
  });

  it("does not call gtag when the meta tag is absent", () => {
    document.head.innerHTML = ""; // remove the meta tag
    fireTurbolinksLoad();

    expect(mockGtag).not.toHaveBeenCalled();
  });

  it("does not throw when gtag is not defined on window", () => {
    delete global.gtag;
    expect(() => fireTurbolinksLoad()).not.toThrow();
  });
});
