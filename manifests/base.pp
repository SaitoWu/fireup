# variables
$user = { name => 'deployer', group => 'admin'}
$ruby = { version => 'ruby-1.9.3-p194'}
$application = { name => 'example', root => "/home/${user['name']}/example"}
$mysql = { root_password => 'root'}
$postgresql = { user => 'root', password => 'root'}
$nginx = { root => "/home/${user['name']}/${application['name']}/public/index.htm", server_name => 'localhost'}
$unicorn = { socket => "/tmp/${application['name']}/unicorn.sock"}

# user
user { $user['name']:
  managehome => true,
  ensure     => present,
  shell      => "/bin/bash",
  gid        => $user['group'],
  home       => "/home/${user['name']}"
}

# rvm ruby
include rvm

rvm::system_user { $user['name']: ; }

rvm_system_ruby { $ruby['version']:
  ensure => present,
  # default_use => true;
}

rvm_gem { 'bundler':
  ensure => installed,
  ruby_version => $ruby['version'],
  require => Rvm_system_ruby[ $ruby['version'] ];
}

# mysql
class { 'mysql::ruby': }
class { 'mysql::server':
  config_hash => { 'root_password' => $mysql['root_password'] }
}

# postgresql
class { 'postgresql::server':
  version => '9.1',
}
pg_user { $postgresql['user']:
  ensure   => present,
  password => $postgresql['password'],
  createdb   => true,
  createrole => true
}

# mongodb
class { 'mongodb': }

# redis
# class { 'redis': }

# unicorn
file { "/etc/init.d/unicorn":
  mode => "755",
  ensure => "present",
  content => template('base/unicorn.sh.erb');
}

# nginx
package { 'nginx':
  ensure => present;
}

file { "/etc/nginx/sites-enabled/default":
  ensure => absent;
}

file { "/etc/nginx/sites-enabled/${application['name']}":
  ensure  => file,
  content => template('base/nginx.conf.erb'),
  require => Package['nginx'];
}

service { "nginx":
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
  subscribe  => File["/etc/nginx/sites-enabled/${application['name']}"],
  require    => Package['nginx']
}
