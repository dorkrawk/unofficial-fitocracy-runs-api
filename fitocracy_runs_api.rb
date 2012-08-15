require 'json'
require 'sinatra'
require_relative 'fitocracy_runs'

# Dedicated account for API access
un = ""
pw = ""

runs = FitocracyRuns.new
if runs.authenticate(un,pw)

get '/runs' do
	run_data = runs.get_run_data
	content_type :json
	JSON.pretty_generate(run_data)
end

end

get '/*' do
	401
end