// ActionCable subscription callbacks run with `this` bound to the subscription
// object, not the store — so topic filtering uses `lb` (closure) not `this`.

// Hoist mocks before any imports.
jest.mock("../../../app/javascript/channels/consumer", () => ({
  __esModule: true,
  default: {
    subscriptions: {
      create: jest.fn(),
    },
  },
}));

jest.mock("../../../app/javascript/dispatcher", () => ({
  __esModule: true,
  default: {
    register: jest.fn(),
  },
}));

import consumer from "../../../app/javascript/channels/consumer";
import store from "../../../app/javascript/stores/LiveLeaderboardStore";

describe("LiveLeaderboardStore — received callback topic routing", () => {
  let receivedHandler;

  beforeEach(() => {
    // Capture the subscription handlers when listenToLeaderboard is called.
    consumer.subscriptions.create.mockImplementation((_channel, handlers) => {
      receivedHandler = handlers.received;
    });

    // Give the store some baseline data so leaderboardChange won't blow up if called.
    store.weeklyLeaderboard = { 1: { id: 1, score: 50, name: "Alice" } };
    store.currentLeaderboard = { 1: { id: 1, score: 50, name: "Alice" } };
    store.topic = "42"; // store is filtering to a specific topic

    store.listenToLeaderboard();
    consumer.subscriptions.create.mockClear();
  });

  afterEach(() => {
    jest.restoreAllMocks();
    store.topic = undefined;
  });

  it("calls leaderboardChange when the received data topic matches the store topic", () => {
    const spy = jest
      .spyOn(store, "leaderboardChange")
      .mockImplementation(() => {});

    receivedHandler.call({}, { topic: "42", id: 1, subject_score: 100 });

    expect(spy).toHaveBeenCalled();
  });

  it("does NOT call leaderboardChange when the received data topic does not match the store topic", () => {
    const spy = jest
      .spyOn(store, "leaderboardChange")
      .mockImplementation(() => {});

    receivedHandler.call({}, { topic: "99", id: 1, subject_score: 100 });

    expect(spy).not.toHaveBeenCalled();
  });

  it("calls leaderboardChange for any data when the store has no topic filter", () => {
    store.topic = undefined;
    store.listenToLeaderboard(); // re-register with no topic

    const spy = jest
      .spyOn(store, "leaderboardChange")
      .mockImplementation(() => {});

    receivedHandler.call({}, { id: 1, subject_score: 100 });

    expect(spy).toHaveBeenCalled();
  });
});
