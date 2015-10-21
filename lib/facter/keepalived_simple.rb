# Source: https://github.com/purpleidea/puppet-keepalived.git
#

require 'facter'
require 'digest/sha1'
require 'ipaddr'

length = 16
# pass regexp
regexp = /^[a-zA-Z0-9]{#{length}}$/
ipregexp = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
netmaskregexp = /^(((128|192|224|240|248|252|254)\.0\.0\.0)|(255\.(0|128|192|224|240|248|252|254)\.0\.0)|(255\.255\.(0|128|192|224|240|248|252|254)\.0)|(255\.255\.255\.(0|128|192|224|240|248|252|254)))$/
chars = [('a'..'z'), ('A'..'Z'), (0..9)].map { |i| i.to_a }.flatten


# find the module_vardir
dir = Facter.value('puppet_vardirtmp')    # nil if missing
if dir.nil?         # let puppet decide if present!
  dir = Facter.value('puppet_vardir')
  if dir.nil?
    var = nil
  else
    var = dir.gsub(/\/$/, '')+'/'+'tmp/'  # ensure trailing slash
  end
else
  var = dir.gsub(/\/$/, '')+'/'
end

if var.nil?
  # if we can't get a valid vardirtmp, then we can't continue
  module_vardir = nil
  simpledir = nil
  passfile = nil
  ipfile = nil
else
  module_vardir = var+'keepalived/'
  simpledir = module_vardir+'simple/'
  passfile = simpledir+'pass'
  ipfile = simpledir+'ip'
end

# NOTE: module specific mkdirs, needed to ensure there is no blocking/deadlock!
if not(var.nil?) and not File.directory?(var)
  Dir::mkdir(var)
end

if not(module_vardir.nil?) and not File.directory?(module_vardir)
  Dir::mkdir(module_vardir)
end

if not(simpledir.nil?) and not File.directory?(simpledir)
  Dir::mkdir(simpledir)
end

# generate pass and parent directory if they don't already exist...
if not(module_vardir.nil?) and File.directory?(module_vardir)
  if not File.directory?(simpledir)
    Dir::mkdir(simpledir)
  end

  # create a pass and store it in our vardir if it doesn't already exist!
  if File.directory?(simpledir) and ((not File.exist?(passfile)) or (File.size(passfile) == 0))
    # include a built-in pwgen-like backup
    string = (0..length-1).map { chars[rand(chars.length)] }.join
    result = system("(/usr/bin/test -z /usr/bin/pwgen && /usr/bin/pwgen -N 1 #{length} || /bin/echo '#{string}') > '" + passfile + "'")
    if not(result)
      # TODO: print warning
    end
  end
end

# create the fact if the pass file contains a valid pass
if not(passfile.nil?) and File.exist?(passfile)
  pass = File.open(passfile, 'r').read.strip    # read into str
  # skip over pass's of the wrong length or that don't match (security!!)
  if pass.length == length and regexp.match(pass)
    Facter.add('keepalived_simple_pass') do
      #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
      setcode {
        # don't reuse pass variable to avoid bug #:
        # http://projects.puppetlabs.com/issues/22455
        pass
      }
    end
  # TODO: print warning on else...
  end
end

# create facts from externally collected pass files
_pass = ''
found = {}
prefix = 'pass_'
if not(simpledir.nil?) and File.directory?(simpledir)
  Dir.glob(simpledir+prefix+'*').each do |f|

    b = File.basename(f)
    # strip off leading prefix
    fqdn = b[prefix.length, b.length-prefix.length]

    _pass = File.open(f, 'r').read.strip.downcase # read into str
    if _pass.length == length and regexp.match(_pass)
      # avoid: http://projects.puppetlabs.com/issues/22455
      found[fqdn] = _pass
    # TODO: print warning on else...
    end
  end
end

#found.keys.each do |x|
# Facter.add('keepalived_simple_'+x) do
#   #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
#   setcode {
#     found[x]
#   }
# end
#end

#Facter.add('keepalived_simple_facts') do
# #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
# setcode {
#   found.keys.collect {|x| 'keepalived_simple_'+x }.join(',')
# }
#end

# distributed password (uses a piece from each host)
collected = found.keys.sort.collect {|x| found[x] }.join('#') # combine pieces
Facter.add('keepalived_simple_password') do
  #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
  setcode {
    Digest::SHA1.hexdigest(collected)
  }
end

Facter.add('keepalived_simple_fqdns') do
  #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
  setcode {
    # sorting is very important
    found.keys.sort.join(',')
  }
end

# create these facts if the ip file contains a valid ip address
if not(ipfile.nil?) and File.exist?(ipfile)
  ip = File.open(ipfile, 'r').read.strip.downcase # read into str
  # skip over ip that doesn't match (security!!)
  if ipregexp.match(ip)

    # TODO: replace with system-getifaddrs if i can get it working!
    cmd = "/sbin/ip -o a show to #{ip} | /bin/awk '{print $2}'"
    interface = `#{cmd}`.strip
    if $?.exitstatus == 0 and interface.length > 0

      Facter.add('keepalived_simple_interface') do
        #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
        setcode {
          interface
        }
      end

      # lookup from fact
      netmask = Facter.value('netmask_'+interface)
      if netmaskregexp.match(netmask)

        Facter.add('keepalived_simple_netmask') do
          #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
          setcode {
            netmask
          }
        end

        cidr = IPAddr.new("#{netmask}").to_i.to_s(2).count('1')
        Facter.add('keepalived_simple_cidr') do
          #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
          setcode {
            cidr
          }
        end
      end

    # TODO: print warning on else...
    end

  # TODO: print warning on else...
  end
end
