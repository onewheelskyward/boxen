require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $luser,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::luser}"
  ]
}

File {
  group => 'staff',
  owner => $luser
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => Class['git'],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

#  include property_list_key
#  include osx
#  include phpstorm
#  include rubymine

#  package { 'Gephi':
#    ensure   => installed,
#    source   => 'https://launchpadlibrarian.net/98903476/gephi-0.8.1-beta.dmg',
#    provider => appdmg,
#  }

  package {
    [  'mysql',
      'postgresql',
      'mongodb',
      'redis',
      'fish',
    ]:
  }

package { 'RubyMine':
	ensure => installed,
	source => 'http://download.jetbrains.com/ruby/RubyMine-5.4.3.dmg',
	provider => appdmg
}

package { 'PhpStorm':
	ensure => installed,
	source => 'http://download.jetbrains.com/webide/PhpStorm-6.0.3.dmg',
	provider => appdmg
}
package { 'Textual':
	ensure => installed,
	source => 'http://www.codeux.com/textual/private/downloads/builds/trial-versions/Textual-Trial-g441bee9.zip',
	provider => compressed_app
}
package { 'Sublime Text 3 build 3047':
  ensure => installed,
  source => 'http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%20Build%203047.dmg',
  provider => appdmg
}
package { 'Dropbox':
  ensure => installed,
  source => 'https://d1ilhw0800yew8.cloudfront.net/client/Dropbox%202.0.26.dmg',
  provider => appdmg
}
package { 'Alfred':
  ensure => installed,
  source => 'http://cachefly.alfredapp.com/Alfred_2.0.6_203.zip',
  provider => compressed_app
}
package { 'iTerm2':
  ensure => installed,
  source => 'http://www.iterm2.com/downloads/beta/iTerm2-1_0_0_20130624.zip',
  provider => compressed_app
}

  # do not fail if FDE is not enabled
#  if $::root_encrypted == 'no' {
#    fail('Please enable full disk encryption and try again')
#  }

  # node versions
  include nodejs::v0_4
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  # default ruby versions
  include ruby::1_9_3
  include ruby::2_0_0

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }
  file { "/Users/akreps/src/black-pepper":
      ensure => "directory",
  }
  file { "/Users/akreps/logs":
      ensure => "directory",
  }

  repository {
    'black pepper':
      source   => 'git@github.com:Athletepath/black-pepper',
      path     => '/Users/akreps/src/black-pepper',
      provider => 'git'
  }

  repository {
    'athletepath':
      source   => 'git@github.com:Athletepath/Athletepath',
      path     => '/Users/akreps/src/athletepath',
      provider => 'git'
  }

#  exec {"load-repos":
#    command =>"git clone git@github.com:Athletepath/black-pepper /Users/akreps/",
#    require => Package["git-core"],
#  }
}
