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
  token = ENV["GITLAB_PRIV_TOKEN"]
  project_id = 2948448
  issue = GitlabIssue.new(token, project_id, params)
  issue.send
  redirect to "/"
end

not_found do
  status 404
  slim :oops
end