require './lib/gitlab_issue.rb'

get '/' do
  slim :index
end

get '/contact' do
  slim :contact
end

get '/about' do
  slim :about
end

get '/faq' do
  slim :faq
end

get '/guides' do
  slim :guides
end

get '/install' do
  slim :install
end

get '/guides/:guide' do
  guide = params[:guide]

  begin
    @body = File.open("#{File.dirname(__FILE__)}/guides/#{guide}.md", "rb").read
  rescue
    error 404
  end
  
  slim :guide
end

get '/bug' do
  slim :bug
end

get '/feedback' do
  slim :feedback
end

post '/feedback' do
  token = ENV["PENNY_GITLAB_TOKEN"]
  project_id = 2776350 # penkit/penkit
  milestone_id = 287139 # User feedback milestone

  # Captcha
  res = Net::HTTP.post_form(
    URI.parse('https://www.google.com/recaptcha/api/siteverify'),
    {
      'secret' => ENV["PENKIT_CAPTCHA_SECRET"],
      'remoteip'   => request.ip,
      'response'   => params["g-recaptcha-response"]
    }
  )

  body = JSON.parse(res.body)

  if body["success"] == true
    issue = GitlabIssue.new(token, project_id, milestone_id , params)
    issue.send
    json :success => 'true'
  else
    json :success => 'false'
  end 
end

not_found do
  status 404
  slim :oops
end