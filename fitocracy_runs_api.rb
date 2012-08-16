require 'json'
require 'sinatra'
require_relative 'fitocracy_runs'
require_relative 'auth_account'

# Dedicated account for API access
auth_account = AuthAccount.new
un = auth_account.username
pw = auth_account.password

runs = FitocracyRuns.new(un,pw)
if runs.authenticate
	get '/runs/' do
		no_un = Hash.new
		no_un["error"] = "Missing username"
		content_type :json
		JSON.pretty_generate(no_un)
	end

	get '/runs/:username' do
		run_data = runs.get_run_data(params[:username])
		content_type :json
		JSON.pretty_generate(run_data)
	end

	not_found do
		bad_path = Hash.new
		bad_path["error"] = "Bad path"
		content_type :json
		JSON.pretty_generate(bad_path)
	end
else
	get '/*' do
		bad_auth = Hash.new
		bad_auth["error"] = "API authentication failed"
		content_type :json
		JSON.pretty_generate(bad_auth)
	end
end