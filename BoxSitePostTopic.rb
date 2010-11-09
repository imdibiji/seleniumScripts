require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
url = ''
prefix = 'qa'
endnum = 0
emailaddress = "foo@bar.com"
password = "password"
categories = ['Questions','Random Talk','Getting Started']
usage = "Usage: -p <prefix to use>
   -u base url
   -e ending index
   -a email address to login with
   -P password
  e.g. ruby #{$0} -u http://appcert01-sony.eng.powered.com:8072/ -p \"this is a test\" -e 10 -a qa42@powered.com -P password"

# process command line options
opts = GetoptLong.new(
    [ "--url", "-u", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--emailaddress", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--password", "-P", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts usage
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--url"
      url = arg
    when "--prefix"
      prefix = arg
    when "--endnum"
      endnum = arg.to_i
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
    else
      puts usage
      Process.exit!
    end
  }
end

# create instance of selenium client
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", url, 10000);
selenium.start
selenium.allow_native_xpath("false")
selenium.set_context("test_box_site_post_topic")

# go home and logout if necessary.  Then login.
puts "login"
selenium.open "/"
if selenium.element? "link=Logout"
  selenium.click "link=Logout"
  selenium.wait_for_page_to_load "30"
end
selenium.open "/login"
selenium.wait_for_page_to_load "30000"
if (selenium.element? "emailAddress") && (selenium.element? "LoginSubmit")
  selenium.click "emailAddress"
  selenium.type "emailAddress", emailaddress
  selenium.type "password", password
  selenium.click "LoginSubmit"
  selenium.wait_for_page_to_load "30000"
else
  puts "could not login!"
  Process.exit!
end

# post a message board topic
puts endnum
(1..endnum).each do |index|
#for index in 1..endnum
  selenium.click "xpath=//a[matches(@href,'/discussions/home')]"
  selenium.wait_for_page_to_load "30000"
  selenium.click "xpath=//a[matches(@href,'/discussions/new')]"
  selenium.wait_for_page_to_load "30000"
  puts "posting topic: #{Time.now}: #{prefix} : #{index}"
  selenium.type "topicTitle", "#{Time.now}: #{prefix} : #{index} #{getString(3)}"
  selenium.select "Category", "label=#{categories[rand(categories.length)]}"
  selenium.type "editorArea", getString(100)
  selenium.click "MessageBoardSubscribe"
  selenium.click "link=Post"
  selenium.wait_for_page_to_load "30000"
end

puts "selenium stop"
selenium.stop
