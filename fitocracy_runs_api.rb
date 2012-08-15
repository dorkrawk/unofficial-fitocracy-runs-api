require 'json'
require 'sinatra'
require_relative 'fitocracy_runs'

get '/runs.json' do
	content_type :json
	JSON.pretty_generate(run_data)
end

get '/bad' do
	403
end