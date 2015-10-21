# == Class keepalived
#
class keepalived::service {

  if $::keepalived::service_manage == true {
    if $::keepalived::service_systemd {
      file { '/etc/systemd/system/keepalived.service':
        ensure  => file,
        source  => 'puppet:///modules/keepalived/systemd/keepalived.service',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package[$::keepalived::pkg_list],
      }
      service { $::keepalived::service_name:
        ensure     => $::keepalived::service_ensure,
        enable     => $::keepalived::service_enable,
        hasrestart => $::keepalived::service_hasrestart,
        hasstatus  => $::keepalived::service_hasstatus,
        provider   => 'systemd',
        require    => [ Class['::keepalived::config'],
                        File['/etc/systemd/system/keepalived.service'],
                      ],
        restart    => $::keepalived::service_restart,
      }
    }
    else {
      service { $::keepalived::service_name:
        ensure     => $::keepalived::service_ensure,
        enable     => $::keepalived::service_enable,
        hasrestart => $::keepalived::service_hasrestart,
        hasstatus  => $::keepalived::service_hasstatus,
        require    => Class['::keepalived::config'],
        restart    => $::keepalived::service_restart,
      }
    }
  }
}

