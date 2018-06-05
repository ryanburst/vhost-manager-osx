#!/usr/bin/env ruby
# Working with Apache 2.4 and Mac OS Sierra by SwankyLynx

HOSTS = "/etc/hosts"
VHOSTSDIR = "/etc/apache2/extra/vhosts/" # needs trailing slash
DEFAULTS = {
  "webroot" => false
}

def usage(command = false)
  if command == 'add'
    puts "\tUSAGE: sudo vhostman add name --webroot"
  elsif command == 'edit'
    puts "\tUSAGE: sudo vhostman edit name [--new] [--webroot]"
  elsif command == 'remove'
    puts "\tUSAGE: sudo vhostman remove name"
  else
    puts "\tUSAGE: sudo vhostman add|edit|remove name [--new] [--webroot]"
  end
  exit
end

def check_args
  if ARGV.count < 2
    usage
  elsif not ['add','edit','remove'].include?(ARGV[0])
    usage
  end

  @command = ARGV[0]
  @domain = ARGV[1]
  @vhost_path = vhostPath()
  @options = parseOptions()

  # Add must have three arguments, the command, the name of the site, and the webroot
  if @command == 'add' && (ARGV.count != 3 || !@options['webroot'])
    usage(@command)
  # Edit must have at least three arguments, the command, the name of the site, and either the
  # new name of the site or a new webroot
  elsif @command == 'edit' && (ARGV.count < 3 || (!@options['new'] && !@options['webroot']))
    usage(@command)
  end

  if @options['webroot']
    @webroot = File.expand_path @options['webroot'].chomp('/')
  end

  if @options['new']
    @new_domain = @options['new']
  end
end

def parseOptions
  return DEFAULTS.merge(Hash[ ARGV.flat_map{|s| s.scan(/--?([^=\s]+)(?:=(\S+))?/) } ])
end

def vhostPath(fileName = false)
  return VHOSTSDIR + (fileName ? fileName : @domain) + '.conf'
end

def check_permission
  if !File.exists? VHOSTSDIR
    puts "\tERROR: VHOSTDIR #{VHOSTSDIR} not found. Please create it."
    exit
  end
  if !File.writable? VHOSTSDIR
    puts "\tERROR: VHOSTDIR #{VHOSTSDIR} not writable. Re-run with 'sudo'."
    exit
  end
  if !File.exists? HOSTS
    puts "\tERROR: HOSTS #{HOSTS} not found."
    exit
  end
  if !File.writable? HOSTS
    puts "\tERROR: HOSTS #{HOSTS} not writable. Re-run with 'sudo'."
    exit
  end
end

def check_webroot_path
  if !File.directory?(@webroot)
    puts "\tERROR: Specified webroot dir '#{@webroot}' does not exist."
    puts "\tMake it first -> mkdir #{@webroot}"
    exit
  end
end

def check_vhost_path
  if !File.exists? @vhost_path
    puts "\tERROR: VHost file for '#{@domain}' does not exist at webroot '#{@webroot}'."
    exit
  end
end

def check_vhost_path_for_add
  if File.exists? @vhost_path
    puts "\tERROR: VHost file for '#{@domain}' already used."
    exit
  end
end

def make_vhost
  puts "\tMaking vhost file in #{@vhost_path}..."
  File.open(@vhost_path, 'w') do |f|
    f.puts "<VirtualHost *:80>"
    f.puts "  ServerAdmin webmaster@#{@domain}"
    f.puts "  DocumentRoot \"#{@webroot}\""
    f.puts "  ServerName #{@domain}"
    f.puts "  ServerAlias www.#{@domain}"
    f.puts "  ErrorLog \"/private/var/log/apache2/#{@domain.split(/\s|\./)[0]}-error_log\""
    f.puts "  CustomLog \"/private/var/log/apache2/#{@domain.split(/\s|\./)[0]}-access_log\" common"
    f.puts "  <Directory \"#{@webroot}\">"
    f.puts "    Options Indexes FollowSymLinks MultiViews"
    f.puts "    AllowOverride All"
    f.puts "    Require all granted"
    f.puts "  </Directory>"
    f.puts "</VirtualHost>"
  end
end

def edit_vhost
  puts "\tEditing vhost file in #{@vhost_path}..."
  puts "\tChanging #{@domain} to #{@new_domain}"
  data = File.read(@vhost_path);
  File.open(@vhost_path, 'w') do |f|
    data.split("\n").each do |line|
      f.puts line.gsub(/#{Regexp.escape(@domain)}/,@new_domain)
    end
  end
  File.rename(@vhost_path, VHOSTSDIR + @new_domain + '.conf')
end

def remove_vhost
  puts "\tRemoving vhost file #{@vhost_path}..."
  File.delete(@vhost_path);
end

def add_to_hosts
  puts "\tAdding #{@domain} to #{HOSTS}..."
  File.open(HOSTS, 'a') do |f|
    f.puts "127.0.0.1 #{@domain}"
  end
end

def remove_from_hosts
  puts "\tRemoving #{@domain} from #{HOSTS}..."
  data = File.read(HOSTS);
  File.open(HOSTS, 'w') do |f|
    data.split("\n").each do |line|
      if line !~ /#{@domain}/
       f.puts line
      end
    end
  end
end

def restart_apache
  puts "\tRestarting apache..."
  if !`apachectl restart`
    puts "\tERROR: Error restarting apache."
  end
end

def show_complete
  if ['add','edit'].include?(@command)
    puts "\tOK! Site should be visible at http://#{@domain}"
  else
    puts "\tOK! Site http://#{@domain} removed"
  end
end

def addSite
  check_webroot_path
  check_vhost_path_for_add
  add_to_hosts
  make_vhost
end

def editSite
  check_vhost_path
  if @options['new']
    edit_vhost
    remove_from_hosts
    @domain = @new_domain
    add_to_hosts
  end
  if @options['webroot']
    remove_vhost
    @vhost_path = vhostPath()
    check_webroot_path
    make_vhost
  end
end

def removeSite
  check_vhost_path
  remove_from_hosts
  remove_vhost
end

def run
  check_args
  check_permission
  send("#{@command}Site")
  restart_apache
  show_complete
end

# ----
run
