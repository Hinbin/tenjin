import React from 'react'
function WithLoading (Component) {
  return function WithLoadingComponent ({ isLoading, ...props }) {
    if (!isLoading) return (<Component {...props} />)
    return (<div className='loader'>Loading...</div>)
  }
}
export default WithLoading
