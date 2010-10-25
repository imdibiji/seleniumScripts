require 'rubygems'
require "selenium"
require "getoptlong"
require 'BoxSiteHelperModule.rb'
include BoxSiteHelperModule

# init
prefix = 'qa'
topicid = 0
startnum = 0
endnum = 0
courseName = ''
emailaddress = "foo@bar.com"
password = "boguspassword"

# process command line options
opts = GetoptLong.new(
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--courseName", "-c", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--startnum", "-s", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--emailaddress", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--password", "-P", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts 'Usage: -p <prefix to use>
   -c course name
   -s starting index
   -e ending index
   -a email address to login with
   -P passowrd
  e.g. ruby $0 -c "The Civil War" -p "this is a test" -s 1 -e 10 -a qa42@powered.com -P password'
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--prefix"
      prefix = arg
    when "--courseName"
      courseName = arg
    when "--startnum"
      startnum = arg.to_i
    when "--endnum"
      endnum = arg.to_i
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
    else
      puts 'Usage: -p <prefix to use>
       -c course name
       -s starting index
       -e ending index
       -a email address to login with
       -P passowrd
      e.g. ruby $0 -p "this is a test" -s 1 -e 10 -a qa42@powered.com -P password'
      Process.exit!
    end
  }
end

# create instance of selenium client, and connect to box running at rons url
selenium = Selenium::SeleniumDriver.new("localhost", 4444, "*chrome", "http://appcert01-rons.eng.powered.com:8075/", 10000);
# don't use native xpath cuz FF is teh weak
selenium.start
selenium.allow_native_xpath("false")
selenium.set_context("test_box_site_post_content_comment")

# go home and logout if necessary.  Then login.
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
end

# go to content , click link for appropriate content and then post comments
selenium.open "/content"
selenium.wait_for_page_to_load "30000"
selenium.wait_for_element "link=#{courseName}"
if selenium.element? "link=#{courseName}"
  selenium.click "link=#{courseName}"
  selenium.wait_for_page_to_load "30000"
else
  puts "couldn't find course link"
  Process.exit!
end
# begin loop for posting comments
for index in startnum..endnum
  puts "posting comment index: #{index}"
  selenium.wait_for_element "//textarea[@name='commentText']"
  commentString = getString(30)
  if selenium.element? "//textarea[@name='commentText']"
    selenium.type "commentText", "#{Time.now}: #{prefix} : #{index}\n #{commentString}"
  end
  selenium.click "link=Leave Comment"
  selenium.wait_for_text(commentString, :element => "message", :timeout_in_seconds => 5 )
end
selenium.stop
