import React from 'react'
import PropTypes from 'prop-types'

export default class ClassroomWinner extends React.Component {
  render () {
    const { classroom, winners } = this.props

    const winner = winners.filter((w) => {
      return w[0] === classroom
    })
    const winnerElement = <p><b className='font-weight-bold'>{`${classroom} winner: `}</b>
      {winner.map((w) => `${w[1]} - ${w[2]} points`).join(', ')}</p>
    return (

      <div>
        {classroom &&
          winnerElement
        }
      </div>
    )
  }
}

ClassroomWinner.propTypes = {
  classroom: PropTypes.string,
  winners: PropTypes.array
}
