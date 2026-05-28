// componentDidUpdate must respond to changes in either `filters` or `currentFilters`.
// Checking only one means new filter categories can appear without the component re-rendering.

import '@testing-library/jest-dom';
import React from 'react';
import { render, screen } from '@testing-library/react';
import Filters from '../../../app/javascript/components/live_leaderboard/Filters';

// Stub Filter to avoid reactstrap complexity; we only care whether Filters
// passes updated data down to it.
jest.mock('../../../app/javascript/components/live_leaderboard/Filter', () => {
  const React = require('react');
  return function MockFilter({ name }) {
    return React.createElement('div', { 'data-testid': 'filter' }, name);
  };
});

describe('Filters — prop change detection', () => {
  it('renders a new filter when the filters prop changes but currentFilters ref is unchanged', () => {
    const stableCurrentFilters = [];

    const { rerender } = render(
      <Filters filters={{}} currentFilters={stableCurrentFilters} />,
    );

    expect(screen.queryByTestId('filter')).toBeNull();

    const newFilters = {
      classroom: { name: 'Class', options: ['All', 'Mathematics'], default: 'Select Class' },
    };
    rerender(<Filters filters={newFilters} currentFilters={stableCurrentFilters} />);

    expect(screen.getByTestId('filter')).toBeInTheDocument();
    expect(screen.getByText('Class')).toBeInTheDocument();
  });
});
