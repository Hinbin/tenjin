import React from 'react'
import PropTypes from 'prop-types'
import Filter from './Filter'

class Filters extends React.Component {
  constructor (props) {
    super(props)

    this.toggle = this.toggle.bind(this)

    this.state = {
      dropdownOpen: false,
      filters: props.filters,
      currentFilters: props.currentFilters
    }
  }

  componentDidUpdate (prevProps) {
    if (
      this.props.currentFilters !== prevProps.currentFilters ||
      this.props.filters !== prevProps.filters
    ) {
      this.setState({
        filters: this.props.filters,
        currentFilters: this.props.currentFilters,
      })
    }
  }

  toggle () {
    this.setState({
      dropdownOpen: !this.state.dropdownOpen
    })
  }

  render () {
    const { filters, currentFilters } = this.state

    let filterArray = []

    // Display all filters that are currently defined.
    for (const filter of Object.values(filters)) {
      let selected = currentFilters.filter((selectedFilter) => {
        return selectedFilter.name === filter.name
      })[0]
      if (selected === undefined) {
        selected = filter.default
      } else {
        selected = selected.option
      }
      filterArray.push(<Filter key={filter.name} selected={selected} {...filter} />)
    }

    return (
      filterArray
    )
  }
}

Filters.propTypes = {
  filters: PropTypes.object.isRequired,
  currentFilters: PropTypes.array.isRequired,
}

export default Filters
