require "base64"
require "curb"
require "json"
require "thread"

$CONFIG_FILE = File.join(__dir__, "config.json")

$USER_AGENT = 'Something'

$debug=false


if not File.exist?($CONFIG_FILE)
  raise Exception.new("please copy config.json.template to config.json and fill it to your needs")
end

class VRubChat

  def get_creds(config_file)
    j = JSON.parse(File.read(config_file))
    return j["auth"]["username"], j["auth"]["password"], j["apikey"]
  end

  attr_accessor :friends
  def initialize(config_file)
    @username, @password, @apikey = get_creds($CONFIG_FILE)
    @logged_in = false
  end

  def login()
    return if @logged_in
    c = Curl.get("https://vrchat.com/api/1/auth/user?apiKey=#{@apikey}")
    c.http_auth_types = :basic
    c.username = @username
    c.password = @password
    #c.verbose = true
    c.set(:HTTP_VERSION, Curl::HTTP_2_0)
    c.headers["User-Agent"] = $USER_AGENT
    c.perform
    _, *http_headers = c.header_str.split(/[\r\n]+/).map(&:strip)
    @cookies = http_headers.map{|x| x[/set-cookie: ([^;]+);( Max-Age=\d+;)? Path=\//i,1]}.compact

    @logged_in = true
    @data = JSON.parse(c.body_str)
    pp @data if $debug
    @friends = @data["friends"]
    @online_friends = @data["onlineFriends"]
    @offline_friends = @data["offlineFriends"]
    @active_friends = @data["activeFriends"]
  end

  def user_info(user_id)
    login() unless @logged_in
    c = Curl.get("https://vrchat.com/api/1/users/#{user_id}?apiKey=#{@apikey}&userId=#{user_id}")
    c.headers["User-Agent"] = $USER_AGENT
    c.set(:HTTP_VERSION, Curl::HTTP_2_0)                                                                                                       
    c.headers['Cookie'] = @cookies.join('; ')
    c.perform 
    return JSON.parse(c.body_str)
  end
end

client = VRubChat.new($CONFIG_FILE)
client.login

threads = []
friends_info = []
friends_mutex = Mutex.new

if client.friends.size() == 0
  puts("Could not find friends")
  exit
end


client.friends.each do |friend|
  threads << Thread.new(friend, friends_info) do |friend, friends_info| 
    infos = client.user_info(friend) 
    friends_mutex.synchronize {friends_info << infos}
  end
end
threads.each(&:join)

online_peeps = friends_info.select{|x| ["online"].include?(x["state"])}.map{|x| x["displayName"] + " is " + x["state"]}
online_peeps.each {|x| puts x}
