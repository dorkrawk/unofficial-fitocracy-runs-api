require 'rubygems'
require 'mechanize'

class FitocracyRuns
  LOGIN_URL = "https://www.fitocracy.com/accounts/login/?next=%2Flogin%2F"
  PROFILE_URL = 'https://www.fitocracy.com/profile/'
  ONLINE_TEST_URL = 'http://www.fitocracy.com/activity_stream/'
  
	def initialize(un,pw)
		@authenticated = false
		@username = un
		@password = pw
		@agent = Mechanize.new
		@agent.follow_meta_refresh = true
	end

	# Public methods

  def get_uri_response (uri)
    Net::HTTP.start(uri.host, uri.port, :use_ssl => (uri.scheme == 'https'), :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |net_http| net_http.get(uri.request_uri) }
  end

	def authenticate
		login_page = @agent.get(LOGIN_URL)

		login_form = login_page.form_with(:id => 'username-login-form')

		csrfmiddlewaretoken = login_form['csrfmiddlewaretoken']

		logged_in = @agent.post('https://www.fitocracy.com/accounts/login/', {
			"csrfmiddlewaretoken" => csrfmiddlewaretoken,
			"is_username" => "1",
			"json" => "1",
			"next" => "/home/",
			"username" => @username,
			"password" => @password
			})

		validate_login(logged_in) && @authenticated = true
	end

	def get_run_data(username, limit=1.0/0.0)
		run_data = Hash.new

		user_url = PROFILE_URL + username
		user_page = @agent.get(user_url)

		if fitocracy_mainence?(user_page) 
			run_error["error"] = "Fitocracy on maintenance"
			return run_error
		end
		
		if validate_user(user_page, username)
			userpic = get_userpic(user_page)
			userid = get_userid_from_pic(userpic)

			# Fake logging:
			puts "Getting run data for: " + username

			run_data['username'] = username
			run_data['userid'] = userid
			run_data['userpic'] = userpic
			run_data['runs'] = []

			stream_offset = 0
			stream_increment = 15

			user_stream_url = "http://www.fitocracy.com/activity_stream/#{stream_offset.to_s}/?user_id=#{userid}"
			user_stream = @agent.get(user_stream_url)

			# TODO: look into optimizing this better
			run_count = 0
			limit = limit.to_f
			begin
				items = user_stream.search("div.stream_item")
				items.each do |i|
					datetime = get_item_datetime(i)

					actions = i.search("ul.action_detail li") # TODO: change this to xpath to find only runs
					actions.each do |a|
						activity = a.search("div.action_prompt").text
						if activity.include? 'Running'
							runs = a.search("ul li")
							runs.each do|r|
								if run_count < limit
									run_info_i = r.xpath('(./span[contains(@class,"set_user_imperial")]/@title)[1]').text
									run_info_m = r.xpath('(./span[contains(@class,"set_user_metric")]/@title)[1]').text
									if run_info_i.size > 0
										run = Hash.new
										run["datetime"] = datetime[0]
										run["activity"] = activity[0..-2] 
										run_info_i_arr = run_info_i.split(" || ")
										run["time"] = run_info_i_arr[0]
										dist_i = run_info_i_arr[1].split(" ")
										dist_m = run_info_m.split(" || ")[1].split(" ")
										run["distance_i"] = dist_i[0]
										run["units_i"] = dist_i[1]
										run["distance_m"] = dist_m[0]
										run["units_m"] = dist_m[1]
										run["points"] = get_run_points(r)
										note = a.search("ul li.stream_note").map{ |n| n.text }

										run["note"] = note[0] if note
											
										run_data["runs"] << run
										run_count += 1
									end
								else
									break
								end
								break if run_count >= limit
							end
						end
					end
					break if run_count >= limit
				end

				if run_count < limit
					stream_offset += stream_increment
					user_stream_url = "http://www.fitocracy.com/activity_stream/#{stream_offset.to_s}/?user_id=#{userid}"
					user_stream = @agent.get(user_stream_url)
				end
			end while is_valid_stream(user_stream, limit, run_count) && run_count < limit

			return run_data
		else 
			run_error = Hash.new
			run_error["error"] = "Bad username"

			return run_error
		end
	end

	def is_authenticated
		@authenticated
	end

  def fitocracy_offline?
    get_uri_response(URI(ONLINE_TEST_URL)).code != '200'
  end

  def fitocracy_mainence?(user_page)
  	user_page.uri.to_s.include? "maintenance"
  end

	# Private-ish methods

	def validate_login(logged_in_page)
		!(logged_in_page.body.include? "error")
	end

	def validate_user(user_page, username)
		user_page.uri.to_s.include? username
	end

	
	# Pass in user page for best results
	def get_userid(user_page)
		pp user_page.body
		userid_xpath = '(//input[@name="profile_user"]/@value)[1]'
		id = user_page.parser.xpath(userid_xpath)

		id.text
	end

	def get_userid_from_pic(user_pic)
		profile_pos = user_pic.index("profile/")
		end_pos = user_pic.index("/",profile_pos+8)

		user_pic[profile_pos+8..end_pos-1]
	end

	# Pass in user page for best results
	def get_userpic(user_page)
			userpic_xpath = '(//div[@id="profile-hero-panel"]/div/img/@src)[1]'
			pic_img = user_page.parser.xpath(userpic_xpath)

			pic_img.text
	end

	def is_valid_stream(user_stream_page, limit, run_count)
		if run_count >= limit
			false
		end
		!(user_stream_page.search("div.stream-inner-empty").size > 0)
	end

	def get_item_datetime(item)
		return item.search("a.action_time").map{ |n| n.text }
	end

	def get_run_points(run)
		run_info = run.text
		point_start = run_info.index("(+")
		point_stop = run_info.index(")",point_start)
		run_info[point_start+2..point_stop-5]
	end

end
