export default function updateQuizStatistics (serverResponse) {
  const { multiplier, answeredCorrect, streak } = serverResponse
  $('#multiplier').text(multiplier)
  $('#answeredCorrect').text(answeredCorrect)
  $('#streak').text(streak)
}