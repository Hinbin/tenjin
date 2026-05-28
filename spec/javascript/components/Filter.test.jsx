// ID generation uses a global replace so multi-word names (e.g. "Bishop High School")
// produce valid CSS identifiers. IDs with embedded spaces are unreachable via selectors.

import '@testing-library/jest-dom';
import React from 'react';
import { render, fireEvent, act } from '@testing-library/react';
import Filter from '../../../app/javascript/components/live_leaderboard/Filter';

jest.mock('../../../app/javascript/actions/LiveLeaderboardActions', () => ({
  setFilter: jest.fn(),
}));

describe('Filter — option id generation', () => {
  function renderOpenFilter(name, options) {
    const { container } = render(
      <Filter name={name} options={options} selected={`Select ${name}`} />,
    );
    // Open the dropdown so DropdownMenu renders its items.
    const toggle = container.querySelector('.dropdown-toggle');
    act(() => {
      fireEvent.click(toggle);
    });
    return container;
  }

  it('replaces ALL spaces in a multi-word option name with hyphens in the item id', () => {
    const container = renderOpenFilter('Schools', ['All', 'Bishop High School']);
    expect(container.querySelector('[id="Schools-Bishop-High-School"]')).not.toBeNull();
  });

  it('replaces ALL spaces in a multi-word filter name in the dropdown id', () => {
    // Three-word name needed — two-word names only have one space and pass even with a non-global replace.
    const { container } = render(
      <Filter name="My School Group" options={['A']} selected="Select" />,
    );
    expect(container.querySelector('#My-School-Group-dropdown')).not.toBeNull();
  });
});
