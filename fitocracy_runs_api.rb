require 'json'
require 'sinatra'
require_relative 'fitocracy_runs'

# Dedicated account for API access
un = ""
pw = ""

runs = FitocracyRuns.new(un,pw)
if runs.authenticate
	get '/runs/:username' do
		run_data = runs.get_run_data(params[:username])
		content_type :json
		JSON.pretty_generate(run_data)
	end
end