#  Do advanced content search with various search terms, check for errors.
#  emailaddress and password are required for login, and a filename must be specified
#  that contains the list of search terms

require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
inputfile = ''
emailaddress = ''
password = ''

# process command line options
opts = GetoptLong.new(
    [ "--file", "-f", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--emailaddress", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--password", "-P", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts "Usage: -f filename with search terms
   -a email address to login with
   -P passowrd
  e.g. ruby #{$0} -p \"this is a test\" -f searchTerms.txt -a qa42@powered.com -P password"
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--file"
      inputfile = arg
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
    else
    puts "Usage: -f filename with search terms
     -a email address to login with
     -P passowrd
    e.g. ruby #{$0} -p \"this is a test\" -f searchTerms.txt -a qa42@powered.com -P password"
      Process.exit!
    end
  }
end

# create instance of selenium client
# hardcoding the host for now
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", "http://admcert01-hpms.eng.powered.com:8075/", 10000);
selenium.start
selenium.allow_native_xpath("false")
selenium.set_context("test_workbench_advanced_search")

# go home and logout if necessary.  Then login.
puts "login"
selenium.open "/workbench"
if selenium.element? "link=Logout"
  selenium.click "link=Logout"
  selenium.wait_for_page_to_load "30"
end
if (selenium.element? "username") && (selenium.element? "login")
  selenium.click "username"
  selenium.type "username", emailaddress
  selenium.type "password", password
  selenium.click "login"
  selenium.wait_for_page_to_load "30000"
else
  puts "could not login!"
  Process.exit!
end

# open and read the input file with search terms, each line is a set of one or more
# terms.
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
