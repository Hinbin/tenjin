class Wonde::Endpoints
  # Builds get request and passes it along
  #
  # @param id [String]
  # @param includes [Hash]
  # @param parameters [Hash]
  # @return [Object]
  def get(id, includes = {}, parameters = {})
    parameters['include'] = includes.join(',') unless includes.nil? || includes.empty?
    if parameters.empty?
      uri = self.uri + id
    else
      uriparams = Addressable::URI.new
      uriparams.query_values = parameters
      uri = self.uri + id + '?' + uriparams.query
    end
    response = getRequest(uri)
    puts response if ENV['debug_wonde']
    object = JSON.parse(response, object_class: OpenStruct)
    puts object if ENV['debug_wonde']
    object['data']
  end

  # Forwards request info to unirest
  #
  # @param url [String]
  # @return [Object]
  def getUrl(url)
    RestClient::Request.execute(
      method: :get,
      url: url,
      headers: {
        'Authorization' => "Bearer #{token}",
        'User-Agent' => "wonde-rb-client-#{version}"
      }
    )
  end
end
