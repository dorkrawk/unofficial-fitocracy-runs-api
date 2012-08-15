require 'rubygems'
require 'mechanize'

class FitocracyRuns
	def initialize(un,pw)
		@authenticated = false
		@username = un
		@password = pw
		@userid = ""
		@userpic = ""
		@run_data = Hash.new
		@agent = Mechanize.new
		@agent.follow_meta_refresh = true
  		@agent.user_agent_alias = 'Windows Mozilla'
	end

	# Public methods

	def authenticate
		login_url = "https://www.fitocracy.com/accounts/login/?next=%2Flogin%2F"
		login_page = @agent.get(login_url) # check to make sure this returns a login page (it doesn't if Fitocracy is under maintence)

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

		if validate_login(logged_in)
			@authenticated = true
			return true
		else
			return false
		end
	end

	def get_run_data(username)
		run_data = Hash.new

		user_page = @agent.get("https://www.fitocracy.com/profile/" + username) # need to do a check here to make sure it's a valid username
		
		userid = get_userid(user_page)
		userpic = get_userpic(user_page)

		run_data['username'] = username
		run_data['userid'] = userid
		run_data['userpic'] = userpic
		run_data['runs'] = []

		stream_offset = 0
		stream_increment = 15

		user_stream_url = "http://www.fitocracy.com/activity_stream/" + stream_offset.to_s + "/?user_id=" + userid
		user_stream = @agent.get(user_stream_url)

		begin
			items = user_stream.search("div.stream_item")
			items.each do|i|
				datetime = get_item_datetime(i)

				actions = i.search("ul.action_detail li")
				actions.each do |a|
					activity = a.search("div.action_prompt").text
					if activity.include? 'Running'
						runs = a.search("ul li")
						runs.each do|r|
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

								if note
									run["note"] = note[0]
								end
								run_data["runs"] << run
							end
						end
					end
				end
			end

			stream_offset += stream_increment
			user_stream_url = "http://www.fitocracy.com/activity_stream/" + stream_offset.to_s + "/?user_id=" + userid
			user_stream = @agent.get(user_stream_url)
		end while is_valid_stream(user_stream)

		return run_data
	end

	def is_authenticated
		return @authenticated
	end

	# Private methods

	def validate_login(logged_in_page)
		return true
	end
	
	# Pass in user page for best results
	def get_userid(user_page)
		userid_xpath = '(//input[@name="profile_user"]/@value)[1]'
		id = user_page.parser.xpath(userid_xpath)

		return id.text
	end

	# Pass in user page for best results
	def get_userpic(user_page)
		userpic_xpath = '(//div[@id="profile-hero-panel"]/div/img/@src)[1]'
		pic_img = user_page.parser.xpath(userpic_xpath)

		return pic_img.text
	end

	def is_valid_stream(user_stream_page)
		return !(user_stream_page.search("div.stream-inner-empty").size > 0)
	end

	def get_item_datetime(item)
		return item.search("a.action_time").map{ |n| n.text }
	end

	def get_run_points(run)
		run_info = run.text
		point_start = run_info.index("(+")
		point_stop = run_info.index(")",point_start)
		return run_info[point_start+2..point_stop-5]
	end

end
