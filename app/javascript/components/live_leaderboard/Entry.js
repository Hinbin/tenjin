import React from 'react'
import PropTypes from 'prop-types'

export default class Entry extends React.Component {
  getAwards () {
    let numAwards = this.props.awards
    let awardJSX = []
    while (numAwards >= 5) {
      awardJSX.push(<i key={awardJSX.length} className={'fas fa-star'} style={{ color: 'gold' }} title="Five wins!" data-toggle="tooltip"/>)
      numAwards -= 5
    }

    while (numAwards >= 3) {
      awardJSX.push(<i key={awardJSX.length} className={'fas fa-star'} style={{ color: 'silver' }} title="Three wins!" data-toggle="tooltip"/>)
      numAwards -= 3
    }

    while (numAwards >= 1) {
      awardJSX.push(<i key={awardJSX.length} className={'fas fa-star'} style={{ color: 'red' }} title='Came top of the leaderboard once!' data-toggle='tooltip'/>)
      numAwards -= 1
    }
    return awardJSX
  }

  render () {
    const { lastChanged, currentFilters, user, id } = this.props
    let className = ''
    if (lastChanged) { className += 'score-changed' }

    if (user.id === id) { className += 'font-weight-bold' }

    const checkSchoolFilter = this.props.currentFilters.filter((f) => { return f.name === 'Schools' })

    let contextualRow
    if (checkSchoolFilter.length > 0) {
      contextualRow = <td className='d-none d-lg-block' id={id + '-schools'}>{this.props.school_name}</td>
    } else {
      const classroomNames = this.props.classroom_names
      let classrooms = ''
      if (classroomNames && classroomNames.length > 0) { classrooms = classroomNames.join(', ') }
      contextualRow = <td className='d-none d-lg-block' id={id + '-classrooms'}>{classrooms}</td>
    }

    let icon
    if (this.props.icon) {
      let iconArray = this.props.icon.split(',')
      icon = <i className={`fas fa-${iconArray[1]}`} style={{ color: iconArray[0] }}/>
    }

    return (
      <tr id={id} className={className}>
        <td id={id + '-pos'}>{this.props.position}</td>
        <td id={id + '-awards'}>{this.getAwards()}</td>
        <td id={id + '-name'}>{this.props.name}</td>
        <td id={id + '-icon'}>{icon}</td>
        {contextualRow}
        <td id={id + '-score'}>{this.props.score}</td>
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
