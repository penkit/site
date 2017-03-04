get '/' do
  slim :index
end

not_found do
  status 404
  slim :oops
end