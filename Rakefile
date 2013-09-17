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
require 'rdoc/task'

# load the shared rake files from the package itself
# skip 'package-local' task, it's redefined here
require_relative 'lib/packaging/tasks'
require_relative 'lib/packaging/configuration'
Packaging::Tasks.loadTasks(:exclude => ["package-local.rake"])


# define clean and clobber tasks
require 'rake/clean'
CLEAN.include("package/*.spec", "package/*.gem")
CLOBBER.include("*.gem", "*.gemspec")
task :clobber => :clean


def read_version
    version = `cat VERSION`
    version.chomp
end

# generate a file from .in template, replace @VERSION@ string by VERSION file content
def version_update(filein, fileout = nil)
    if filein.nil? || filein.empty?
	puts "ERROR: empty input or output filename"
	exit 1
    end

    if fileout.nil? || fileout.empty?
	filein =~ /(.*)\.in$/
	fileout = $1
    end

    version = read_version

    puts "Updating #{fileout} (#{version})..."
    `sed -e 's|@VERSION@|#{version}|' #{filein} > #{fileout}`
end

# generate .gemspec file from the template
file "packaging_rake_tasks.gemspec" => ["packaging_rake_tasks.gemspec.in", "VERSION"] do
    version_update("packaging_rake_tasks.gemspec.in")
end


# generate RPM .spec file from the template
file "package/rubygem-packaging_rake_tasks.spec" => ["rubygem-packaging_rake_tasks.spec.in", "VERSION"] do
    version_update("rubygem-packaging_rake_tasks.spec.in", "package/rubygem-packaging_rake_tasks.spec")
end

# build the gem package
desc 'Build gem package, save RPM sources to package subdirectory'
task :"package-local" => [:clean,'packaging_rake_tasks.gemspec', 'package/rubygem-packaging_rake_tasks.spec'] do
    Dir["*.gem"].each do |g|
      rm g
    end
    version = read_version
    sh 'gem build packaging_rake_tasks.gemspec' unless uptodate?("packaging_rake_tasks-#{version}.gem", FileList["lib/**/*"])
    cp "packaging_rake_tasks-#{version}.gem", "package"
end

desc 'Install packaging_rake_tasks gem package'
task :install do
    sh 'gem install packaging_rake_tasks'
end

desc 'Run test suite'
task :test do
    puts 'no test yet'
end

Packaging::Configuration.run do |conf|
  conf.obs_project = "devel:languages:ruby:extensions"
  conf.package_name = "rubygem-packaging_rake_tasks"
end
# vim: ft=ruby
