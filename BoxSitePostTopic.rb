require 'rubygems'
require "selenium"
require "getoptlong"
require 'webster'

# some helper functions
def getString(numberOfWords)
  wordGenerator = Webster.new
  words = ''
  for i in 1..numberOfWords
    words += "#{wordGenerator.random_word} "
  end
  return words
end

# init
prefix = 'qa'
endnum = 0
emailaddress = "foo@bar.com"
password = "password"
#categories = ['Questions','Announcements','Random Talk','Getting Started']
categories = ['Questions','Random Talk','Getting Started']

# process command line options
opts = GetoptLong.new(
    [ "--prefix", "-p", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--endnum", "-e", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--emailaddress", "-a", GetoptLong::REQUIRED_ARGUMENT ],
    [ "--password", "-P", GetoptLong::REQUIRED_ARGUMENT ]
)

unless ARGV.length > 0
  puts "Usage: -p <prefix to use>
   -e ending index
   -a email address to login with
   -P passowrd
  e.g. ruby #{$0} -p \"this is a test\" -s 1 -e 10 -a qa42@powered.com -P password"
  exit
end

begin
  opts.each { |opt, arg|
    case opt
    when "--prefix"
      prefix = arg
    when "--endnum"
      endnum = arg.to_i
    when "--emailaddress"
      emailaddress = arg
    when "--password"
      password = arg
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
  selenium.open "/discussions/home"
  selenium.click "link=Talking"
  selenium.wait_for_page_to_load "30000"
  selenium.click "link=Start talking"
  selenium.wait_for_page_to_load "30000"
  puts "posting topic: #{Time.now}: #{prefix} : #{index}"
  selenium.type "topicTitle", "#{Time.now}: #{prefix} : #{index} #{getString(3)}"
  selenium.select "Category", "label=#{categories[rand(categories.length)]}"
#  selenium.type "editorArea", "#{index}: this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body.  this is the body."
  selenium.type "editorArea", getString(100)
  selenium.click "MessageBoardSubscribe"
  selenium.click "link=Post"
  selenium.wait_for_page_to_load "30000"
end

puts "selenium stop"
selenium.stop
