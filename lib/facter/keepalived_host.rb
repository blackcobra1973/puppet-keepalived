# Source: https://github.com/purpleidea/puppet-keepalived.git
#
require 'facter'
require 'resolv'

# try and pick the _right_ ip that keepalived should use by default...
fqdn = Facter.value('fqdn')
if not fqdn.nil?
  ip = Resolv.getaddress "#{fqdn}"
  if not ip.nil?
    Facter.add('keepalived_host_ip') do
      #confine :operatingsystem => %w{CentOS, RedHat, Fedora}
      setcode {
        ip
      }
    end
  end
end
}
