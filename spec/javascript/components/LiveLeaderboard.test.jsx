import '@testing-library/jest-dom';
import React from 'react';
import { render, unmountComponentAtNode } from 'react-dom';
import { act } from 'react-dom/test-utils';

import LiveLeaderboardStore from '../../../app/javascript/stores/LiveLeaderboardStore';
import * as LiveLeaderboardActions from '../../../app/javascript/actions/LiveLeaderboardActions';

// ─── Mocks ───────────────────────────────────────────────────────────────────

jest.mock('../../../app/javascript/stores/LiveLeaderboardStore', () => ({
  getCurrentLeaderboard: jest.fn().mockReturnValue({}),
  getLoading:            jest.fn().mockReturnValue(false),
  getFilters:            jest.fn().mockReturnValue([]),
  getCurrentFilters:     jest.fn().mockReturnValue([]),
  getUser: jest.fn().mockReturnValue({
    id: 1, role: 'employee', school: 'Test School', classrooms: ['Class A'],
  }),
  getShowAll:    jest.fn().mockReturnValue(false),
  getAllTime:    jest.fn().mockReturnValue(false),
  getLive:      jest.fn().mockReturnValue(false),
  getName:      jest.fn().mockReturnValue('Weekly Leaderboard'),
  getWinners:   jest.fn().mockReturnValue([]),
  getConnected: jest.fn().mockReturnValue(false),
  on:             jest.fn(),
  removeListener: jest.fn(),
}));

jest.mock('../../../app/javascript/actions/LiveLeaderboardActions', () => ({
  loadLeaderboard:       jest.fn(),
  toggleLiveLeaderboard: jest.fn(),
  toggleShowAll:         jest.fn(),
  toggleAllTime:         jest.fn(),
}));

// Make withLoading transparent so the wrapped export is just LiveLeaderboard.
jest.mock('../../../app/javascript/hoc/withLoading', () => (Component) => Component);

// Stub the three sub-components — their rendering is tested separately.
jest.mock('../../../app/javascript/components/live_leaderboard/Entry',           () => () => null);
jest.mock('../../../app/javascript/components/live_leaderboard/Filters',         () => () => null);
jest.mock('../../../app/javascript/components/live_leaderboard/ClassroomWinner', () => () => null);

// ─── Import component AFTER mocks are registered ─────────────────────────────
import LiveLeaderboard from '../../../app/javascript/components/LiveLeaderboard';

// ─── Helpers ─────────────────────────────────────────────────────────────────

let container;

beforeEach(() => {
  container = document.createElement('div');
  document.body.appendChild(container);
  jest.clearAllMocks();
});

afterEach(() => {
  unmountComponentAtNode(container);
  container.remove();
  container = null;
});

function renderLeaderboard() {
  act(() => { render(<LiveLeaderboard />, container); });
}

describe('store subscription lifecycle', () => {
  it('subscribes to store changes on mount', () => {
    renderLeaderboard();
    expect(LiveLeaderboardStore.on).toHaveBeenCalledWith('change', expect.any(Function));
  });

  it('unsubscribes from store changes on unmount, preventing listener leaks', () => {
    renderLeaderboard();

    // Capture the exact listener reference that was registered…
    const [, listener] = LiveLeaderboardStore.on.mock.calls[0];

    act(() => { unmountComponentAtNode(container); });

    // …and verify the same reference is removed.
    expect(LiveLeaderboardStore.removeListener).toHaveBeenCalledWith('change', listener);
  });

  it('triggers data load exactly once on mount', () => {
    renderLeaderboard();
    expect(LiveLeaderboardActions.loadLeaderboard).toHaveBeenCalledTimes(1);
  });
});

describe('loading state', () => {
  // Loading is driven by the store's getLoading(), not the withLoading HOC prop —
  // react-rails never passes props from the server template.
  it('renders a loading indicator while the store reports loading=true', () => {
    LiveLeaderboardStore.getLoading.mockReturnValueOnce(true);
    renderLeaderboard();
    expect(container.querySelector('.loader')).not.toBeNull();
    expect(container.querySelector('#leaderboardTable')).toBeNull();
  });
});
