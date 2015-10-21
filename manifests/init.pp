# == Class keepalived
#
# === Parameters:
#
# $notification_email::       Array of notification email Recipients.
#                             Default: undef.
#
# $notification_email_from::  Define the notification email Sender.
#                             Default: undef.
#
# $smtp_server::              Define the smtp server addres.
#                             Default: undef.
#
# $smtp_connect_timeout::     Define the smtp connect timeout.
#                             Default: undef.
#
# $router_id::                Define the router ID.
#                             Default: undef.
#
class keepalived (
  $config_dir         = '/etc/keepalived',
  $config_dir_mode    = '0755',
  $config_file_mode   = '0644',
  $config_group       = 'root',
  $config_owner       = 'root',
  $daemon_group       = 'root',
  $daemon_user        = 'root',
  $pkg_ensure         = 'present',
  $pkg_list           = [ 'keepalived' ],
  $service_enable     = true,
  $service_ensure     = 'running',
  $service_manage     = true,
  $service_systemd    = false,
#  $service_name       = 'keepalived',
  $service_restart    = undef,
  ## Global Defs parameters
  $notification_email      = undef,
  $notification_email_from = undef,
  $smtp_server             = undef,
  $smtp_connect_timeout    = undef,
  $router_id               = undef,

)
{
  case $::osfamily {
    'redhat': {
      $service_hasstatus  = true
      $service_hasrestart = true
      $service_name       = 'keepalived'
    }

    'debian': {
      $service_hasrestart = false
      $service_hasstatus  = false
      $service_name       = 'keepalived'
    }

    'gentoo': {
      $service_hasrestart = false
      $service_hasstatus  = false
      $service_name       = 'keepalived'
    }

    default: {
      fail "Operating system ${::operatingsystem} is not supported."
    }
  }

  validate_absolute_path($config_dir)
  validate_re($config_dir_mode, '^[0-9]+$')
  validate_re($config_file_mode, '^[0-9]+$')
  validate_string($pkg_ensure)
  validate_bool($service_enable)
  validate_re($service_ensure, ['^running$','^stopped$'])
  validate_bool($service_hasrestart)
  validate_bool($service_hasstatus)
  validate_bool($service_manage)
  validate_string($service_name)

  anchor  { 'keepalived::start': }->
  class   { 'keepalived::install': }->
  class   { 'keepalived::config': }->
  #class   { 'keepalived::global_defs': }->
  class   { 'keepalived::service': }->
  anchor  { 'keepalived::end': }

}

