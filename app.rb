get '/' do
  slim :index
end

get '/contact' do
  slim :contact
end

get '/about' do
  slim :about
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

not_found do
  status 404
  slim :oops
end