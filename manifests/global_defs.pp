# == Class keepalived::global_defs
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
# $ensure::                   Default: present.
#
#
class keepalived::global_defs(
  $notification_email      = $keepalived::notification_email,
  $notification_email_from = $keepalived::notification_email_from,
  $smtp_server             = $keepalived::smtp_server,
  $smtp_connect_timeout    = $keepalived::smtp_connect_timeout,
  $router_id               = $keepalived::router_id,
  $ensure                  = present,
)
{
  concat::fragment { 'keepalived.conf_globaldefs':
    ensure  => $ensure,
    target  => "${::keepalived::config_dir}/keepalived.conf",
    content => template('keepalived/globaldefs.erb'),
    order   => '010',
  }
}
