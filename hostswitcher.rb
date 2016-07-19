#!/usr/bin/env ruby
# __          __              _             _ _ _
# \ \        / /             (_)           | | | |
#  \ \  /\  / /_ _ _ __ _ __  _ _ __   __ _| | | |
#   \ \/  \/ / _` | '__| '_ \| | '_ \ / _` | | | |
#    \  /\  / (_| | |  | | | | | | | | (_| |_|_|_|
#     \/  \/ \__,_|_|  |_| |_|_|_| |_|\__, (_|_|_)
#                                      __/ |
#                                     |___/
# Backup your old /etc/hosts before you start using the hostswitcher:
#   $cp /etc/hosts /etc/hosts.own
#
# If you use the hostswitcher you need to make your individual host
# entries into /etc/hosts.own. Changes in /etc/hosts are temporary
# and will be overwritten while switching environment.
#
# Usage:
#   $./hostswitcher.rb ci #=> command mode
#   $./hostswitcher.rb    #=> interactive mode
 
require "open-uri"
require "tempfile"
 
 
ENV_URL        = "http://dev-as24config.as24.local/GetHostFile.aspx"
ENV_SEPERATOR  = /\s+/
OWN_HOSTS_FILE = "/etc/hosts.own"
HOSTS_FILE     = "/etc/hosts"
HOSTS_FILE_BAK = "/etc/hosts.bak"
OWN_HOSTS_ONLY = "RESET"
PROXY          = false
 
 
def do_with_state(txt)
  print txt.ljust(65)
 
  begin
    print yield ? "[DONE]\n" : "[ERROR]\n"
  rescue Exception => e
    print "[ERROR]\n"
    puts "Message: #{e.message}"
    exit 1
  end
end
 
unless @env = ARGV.first
  do_with_state("Fetch environments") do
    @available_envs = open(ENV_URL, :proxy => PROXY).read.split(ENV_SEPERATOR)
    @available_envs << OWN_HOSTS_ONLY
  end
 
  until @env
    @available_envs.each_with_index do |env, i|
      printf "%2d. %s\n", i, env
    end
 
    print "Use env: "
    @env = @available_envs[$stdin.gets.chop.to_i]
  end
end
 
do_with_state("Backup old hosts file to #{HOSTS_FILE_BAK}") do
  FileUtils.cp HOSTS_FILE, HOSTS_FILE_BAK
  true
end
 
do_with_state("Create Tempfile") do
  @tmp_hosts = Tempfile.new("hosts")
end
 
do_with_state("Begin new #{HOSTS_FILE}") do
  @hosts_file = File.new(HOSTS_FILE, 'w')
end
 
do_with_state("Add own hosts #{OWN_HOSTS_FILE}") do
  @hosts_file << File.open(OWN_HOSTS_FILE, 'r').read
end
 
unless @env == OWN_HOSTS_ONLY
  do_with_state("Add dynamic hosts") do
    host_url = "#{ENV_URL}?environment=#{@env}"
    @hosts_file << open(host_url, :proxy => PROXY).read
  end
end
 
do_with_state("Close #{HOSTS_FILE}") do
  @hosts_file.close
  true
end
