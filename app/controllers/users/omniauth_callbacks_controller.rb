class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def wonde
    # For Wonde - we're not finished when we get a callback response
    # Another request needs to be made to the GraphQL server using
    # the provided bearer token to retrieve user information

    # Setup the GraphQL query that will return all essential information
    query = File.read('app/graphql/user_graphql_query')

    # The bearer token can be found in the response callback
    bearer_token = request.env['omniauth.auth'].credentials['token']

    body = run_graphql_query(query, bearer_token)

    return fail_sign_in unless body.present?

    # Now we have a response with useful user information, send this to
    # our user object.  Standard boiler plate code below
    query_data = extract_query_data(body)

    return fail_sign_in unless query_data.present?

    # You need to implement the method below in your model (e.g. app/models/user.rb)
    user = User.from_omniauth(query_data)
    attempt_user_sign_in(user)
  end

  def attempt_user_sign_in(user)
    if user.blank?
      fail_sign_in
    # persisted? means if the record already existed (or hasn't been deleted)
    # So this effectively prevents a new record from being created if an
    # e-mail has not been found.
    elsif user.persisted?
      sign_in_and_redirect user, event: :authentication
    else
      fail_sign_in
    end
  end

  def fail_sign_in
    flash[:alert] = 'Your account has not been found'
    redirect_to '/'
  end

  def run_graphql_query(query, bearer_token)
    # Connect to the GraphQL interface and run the query.
    # Save the response that has the user information into a response
    # object
    conn = Faraday.new(url: 'https://api.wonde.com/graphql') do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
      faraday.authorization :Bearer, bearer_token
    end

    response = conn.get '/graphql/me', query: query

    JSON.parse response.body
  end

  def extract_query_data(body)
    return unless body.present? && body['data'].present?

    query_data = body['data']['Me']['Person']
    query_data['provider'] = 'Wonde'
    query_data
  end
end
