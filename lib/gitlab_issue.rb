require 'net/http'
require 'openssl'
require 'json'

class GitlabIssue
  attr_accessor :project_id, :private_token, :data

  def initialize(private_token, project_id, data)
    @data = data
    @private_token = private_token
    @project_id = project_id
    @uri = get_uri("https://gitlab.com/api/v4/projects/#{@project_id}/issues")
  end
  
  # Sends message
  def send
    http = create_http # Create HTTP object
    set_ssl(http) # Sets SSL settings
    req = create_request # Create HTTP post object
    req.body =  URI.encode_www_form({ title: data[:title], 
                                      description: format_body(data),
                                      confidential: true
                                    })
    req.add_field("PRIVATE-TOKEN", @private_token)
    http.request(req) # Sends post

  end

  private
    def get_uri(url)
      URI(url)
    end

    def create_http
      Net::HTTP.new(@uri.host, @uri.port)
    end

    def create_request
      Net::HTTP::Post.new(@uri)
    end

    def set_ssl(http)
      http.use_ssl = true
      http
    end

    def format_body(data)
      data.drop(1).map{|k,v| "## #{k.capitalize.gsub('-', ' ')}  \n#{v}  \n"}.join  
    end
end

