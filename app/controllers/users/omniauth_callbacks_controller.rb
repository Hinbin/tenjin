class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def wonde
    # For Wonde - we're not finished when we get a callback response
    # Another request needs to be made to the GraphQL server using
    # the provided bearer token to retrieve user information

    # The bearer token can be found in the response callback
    bearer_token = request.env['omniauth.auth'].credentials['token']

    # Setup the GraphQL query that will return all essential information
    query = <<-GRAPHQL
    {
      Me {
        Person {
          ... on Student {
            type
            forename
            middle_names
            surname
            upi
            Photo {
              id
              content
            }
            School {
              id
              name
            }
          }
          ... on Employee {
            type
            forename
            middle_names
            surname
            upi
            School {
              id
              name
            }
          }
          ... on Contact {
            type
            forename
            middle_names
            surname
            upi
            School {
              id
              name
            }
          }
        }
      }
    }
    GRAPHQL

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

    # Now we have a response with useful user information, send this to
    # our user object.  Standard boiler plate code below

    body = JSON.parse response.body

    query_data = body['data']['Me']['Person']
    query_data['provider'] = 'Wonde'

    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(query_data)

    # persisted? means if the record already existed (or hasn't been deleted)
    # So this effectively prevents a new record from being created if an
    # e-mail has not been found.
    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      flash[:notice] = 'Your account has not been found'
      redirect_to '/users/sign_in'
    end
  end
end
