require 'uri'
require 'json'

get '/' do
  private_token = ENV["GITLAB_TOKEN"]

  source = "https://gitlab.com/api/v3/groups/1356748/projects?private_token=#{private_token}"
  uri = URI.parse(URI.encode(source))
  api_response = Net::HTTP.get(uri)
  @git_results = JSON.parse(api_response)

  slim :index
end

get '/git' do
  private_token = ENV["GITLAB_TOKEN"]

  source = "https://gitlab.com/api/v3/groups/1356748/projects?private_token=#{private_token}"
  uri = URI.parse(URI.encode(source))
  api_response = Net::HTTP.get(uri)
  @results = JSON.parse(api_response)

  slim :git

end