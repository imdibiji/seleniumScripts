require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
usage = "Usage: -u <start url>
   -p <prefix>
   -s <starting index>
   -e <ending index>
e.g. ruby #{$0} -u http://www.yahoo.com -p qa -s 1 -e 10 "
prefix = 'qa'
startnum = 0
endnum = 0
starturl = ''

# process command line options
opts = GetoptLong.new(
    [ "--url", "-u", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--startnum", "-s", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts usage
  Process.exit!
end

begin
  opts.each { |opt, arg|
    case opt
    when "--url"
      starturl = arg
    when "--prefix"
      prefix = arg
    when "--startnum"
      startnum = arg.to_i
    when "--endnum"
      endnum = arg.to_i
    else
      puts usage
      Process.exit!
    end
  }
end


# create instance of selenium client
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", starturl, 10000);
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
  selenium.wait_for_page_to_load "30"
  selenium.type "email", "#{prefix}#{index}@powered.com"
  selenium.type "nameFirst", "#{prefix}#{index}firstname"
  selenium.type "nameLast", "#{prefix}#{index}lastname"
  selenium.type "username", "#{prefix}#{index}username"
  selenium.type "password", "password"
  selenium.type "passwordConfirm", "password"
  selenium.check "attributeValueId1000"
  selenium.check "attributeValueId1001"
  selenium.check "attributeValueId1006"
  selenium.check "attributeValueId1007"
  selenium.select "attribute.1002","label=Friend"
  selenium.click "userAttribute1003"
  selenium.type "attribute.1004", "#{prefix}#{index} street 1"
  selenium.type "attribute.1005", "#{prefix}#{index} street 2"
  selenium.type "attribute.1006", "#{prefix}#{index} city"
  selenium.type "attribute.1008", "#{prefix}#{index} postcode"
  selenium.select "attribute.1007","label=Kentucky"
  selenium.select "attribute.1009","label=Bahamas"
  selenium.type "attribute.1010","#{prefix}#{index} maiden name"
  selenium.type "userAttribute1012","#{prefix}#{index} #{getString(50)}"
  selenium.wait_for_element "userAttribute1014"
  selenium.click "userAttribute1014" unless selenium.checked? "userAttribute1014" 
  selenium.check "attribute.1013Male"
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
