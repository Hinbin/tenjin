import React from 'react'
import PropTypes from 'prop-types'

export default class Entry extends React.Component {
  render () {
    const { lastChanged } = this.props
    let className = ''
    if (lastChanged) {
      className += 'score-changed'
    }

    return (
      <tr id={this.props.id} className={className}>
        <td id={this.props.id + '-pos'}>{this.props.position}</td>
        <td id={this.props.id + '-name'}>{this.props.name}</td>
        <td id={this.props.id + '-school'}>{this.props.school_name}</td>
        <td id={this.props.id + '-score'}>{this.props.score}</td>
      </tr>
    )
  }
}

Entry.propTypes = {
  id: PropTypes.number,
  position: PropTypes.number,
  name: PropTypes.string,
  score: PropTypes.number,
  school: PropTypes.string,
  lastChanged: PropTypes.bool
}
