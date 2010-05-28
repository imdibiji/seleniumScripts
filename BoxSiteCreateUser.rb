require 'rubygems'
require "selenium"
require "getoptlong"

# init
prefix = 'qa'
startnum = 0
endnum = 0

# process command line options
opts = GetoptLong.new(
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--startnum", "-s", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::OPTIONAL_ARGUMENT ]
)

begin
  opts.each { |opt, arg|
    case opt
    when "--prefix"
      prefix = arg
    when "--startnum"
      startnum = arg
    when "--endnum"
      endnum = arg
    else
      puts 'Usage: -c list of clients
   -e environment
   -R Resume previous run
   -n Skip registration of new user before spidering registration
e.g. ruby start_watir_spider.rb -c sony, motorola -e QA, ClientQA '
      Process.exit!
    end
  }
end

# create instance of selenium client
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", "http://appcert01-rons.eng.powered.com:8075/", 10000);
selenium.start
selenium.set_context("test_box_site_create_user")

# register a user
for index in startnum..endnum
  puts "registering #{prefix}#{index}@powered.com"
  # logout if available
  if selenium.element? "link=Logout"
    selenium.click "link=Logout"
    selenium.wait_for_page_to_load "30"
  end
  selenium.open "/register"
  selenium.type "email", "#{prefix}#{index}@powered.com"
  selenium.type "nameFirst", "#{prefix}#{index}firstname"
  selenium.type "nameLast", "#{prefix}#{index}lastname"
  selenium.select "countryId", "label=Anguilla"
  selenium.type "postalCode", "#{prefix}#{index}postcode"
  selenium.type "streetLine1", "#{prefix}#{index}address"
  selenium.type "city", "#{prefix}#{index}city"
  selenium.type "phoneNumber", "#{prefix}#{index}phone"
  selenium.type "username", "#{prefix}#{index}username"
  selenium.type "password", "password"
  selenium.type "passwordConfirm", "password"
  selenium.click "valueId.1100"
  selenium.click "genderMale"
  selenium.click "//input[@value='Submit']"
  selenium.wait_for_page_to_load "30"
  if selenium.element? "link=Logout"
    puts "registered #{prefix}@powered.com."
    selenium.click "link=Logout"
    selenium.wait_for_page_to_load "30"
  else
    puts "no logout link, registration did not succeed"
  end
end
selenium.stop
