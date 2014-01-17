#--
# Webyast Webservice framework
#
# Copyright (C) 2009, 2010 Novell, Inc.
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation.
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require 'rake'

# load the shared rake files from the package itself
# skip 'package-local' task, it's redefined here
require_relative 'lib/packaging/tasks'
require_relative 'lib/packaging/configuration'
Packaging::Tasks.load_tasks(:exclude => ["tarball.rake"])


# define clean and clobber tasks
require 'rake/clean'
CLOBBER.include("package/*.spec", "package/*.gem")
task :clobber => :clean


# generate a file from .in template, replace @VERSION@ string by VERSION file content
def version_update(filein, fileout = nil)
  if filein.nil? || filein.empty?
    raise "ERROR: empty input or output filename"
  end

  if fileout.nil? || fileout.empty?
    filein =~ /(.*)\.in$/
    fileout = $1
  end

  version = File.read("VERSION").chomp

  puts "Updating #{fileout} (#{version})..." if verbose
  `sed -e 's|@VERSION@|#{version}|' #{filein} > #{fileout}`
end

# generate RPM .spec file from the template
file "package/rubygem-packaging_rake_tasks.spec" => ["rubygem-packaging_rake_tasks.spec.in", "VERSION"] do
    version_update("rubygem-packaging_rake_tasks.spec.in", "package/rubygem-packaging_rake_tasks.spec")
end

# build the gem package
desc 'Build gem package, save RPM sources to package subdirectory'
task :"tarball" => [:clean,'packaging_rake_tasks.gemspec', 'package/rubygem-packaging_rake_tasks.spec'] do
  Dir["**/*.gem"].each do |g|
    rm g
  end
  version = File.read("VERSION").chomp
  sh 'gem build packaging_rake_tasks.gemspec' unless uptodate?("packaging_rake_tasks-#{version}.gem", FileList["lib/**/*"])
  mv "packaging_rake_tasks-#{version}.gem", "package"
end

desc 'Install packaging_rake_tasks gem package'
task :install => :tarball do
  sh 'gem install package/packaging_rake_tasks*.gem'
end

desc 'Run test suite'
task :test do
  puts 'no test yet' if verbose
end

Packaging.configuration do |conf|
  conf.obs_project = "devel:languages:ruby:extensions"
  conf.obs_sr_project = "openSUSE:Factory"
  conf.package_name = "rubygem-packaging_rake_tasks"
end
# vim: ft=ruby
