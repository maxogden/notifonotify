# PROBLEM: when someone replies to you publicly in an IRC channel you may not be 
# notified of it if you are away from your computer. The common format for public 
# replies looks like this:
#
#   <jchris> maxo_: yeah mine is way better
#
# SOLUTION: Sign up for notifo as both a supplier and a consumer, and install the 
# notifo app on your smartphone. Execute this in cron every minute to have new 
# mentions sent to your phone as push notifications. 
# 
# This is configured for IRSSI style logs, you can tweak the pattern matching to 
# match whatever logs you want
#
# You will also want to execute this once with the notifo.post line commented out 
# so that it adds all vestigial mentions to the running list of mentions to ignore

require 'notifo'
require 'redis'
require 'digest/md5'

notifo = Notifo.new("NOTIFO_SUPPLIER_USERNAME","NOTIFO_SUPPLIER_SECRET")
redis = Redis.new

publics, privates = [], []

files.each do |file|
  if file =~ /#/
    publics << file
  else
    privates << {:name => file.split(PATH_TO_IRSSI_LOGS)[1].split('.log')[0], :file => file}
  end
end

privates = privates.compact

publics.each do |file|
  File.read(file).each_line do |line|
    digest = Digest::MD5.hexdigest(line)
    if line =~ /YOUR_IRC_USERNAME(,|:)/
      unless redis.sismember "irc_notifications", digest
        redis.sadd "irc_notifications", Digest::MD5.hexdigest(line)
        notifo.post(NOTIFO_SUPPLIER_USERNAME,line)
      end
    end
  end
end

privates.each do |pm|
  File.read(pm[:file]).each_line do |line|
    digest = Digest::MD5.hexdigest(line)
    if line.include? "<#{pm[:name]}>"
      unless redis.sismember "irc_notifications", digest
        redis.sadd "irc_notifications", Digest::MD5.hexdigest(line)
        notifo.post(NOTIFO_SUPPLIER_USERNAME,line)
      end
    end
  end
end