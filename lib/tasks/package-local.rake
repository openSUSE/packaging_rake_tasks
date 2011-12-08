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
require 'fileutils'
require "packaging/configuration"

def package_file_name
  config = Packaging::Configuration.instance
  "#{config.package_name}-#{config.version}"
end

def package_file_path
  File.join(Dir.pwd,Packaging::Configuration.instance.package_dir,
      package_file_name+".tar.bz2")
end

def remove_package_dir
  package_target_dir = File.join(Dir.pwd,Packaging::Configuration.instance.package_dir,
      package_file_name)
  # remove the old package directory
  FileUtils.rm_rf(package_target_dir) if File.directory?(package_target_dir)
end

def remove_old_package
  # remove the old tarball - all versions
  config = Packaging::Configuration.instance
  package_glob = File.join(Dir.pwd,config.package_dir,"#{config.package_name}-*.tar.bz2")
  puts package_glob
  Dir[package_glob].each do |d|
    rm d
  end
end

def package_clean
  remove_package_dir
  remove_old_package
end

# add all GIT files under the current directory to the package_task
def add_git_files(package_task)
  # package only the files which are available in the GIT repository
  filelist = `git ls-files . | grep -v \\.gitignore`.split("\n")

  if $?.exitstatus.zero?
      # add ./ prefix so the exclude patterns match
      filelist.map! { |f| "./#{f}"}

      package_task.package_files.include filelist

      ignored = `git ls-files -o .`.split("\n")

      if $?.exitstatus.zero? and ignored.size > 0
	  ignored.each {|f| $stderr.puts "WARNING: Ignoring file: #{f}"}
      end
  else
      $stderr.puts 'WARNING: Cannot get GIT listing, packaging all files'
      package_task.package_files.include('./**/*')
  end
end

# create new package task
def create_package_task
  require 'rake/packagetask'
  config = Packaging::Configuration.instance
  Rake::PackageTask.new(config.package_name, config.version) do |p|
    p.need_tar_bz2 = true
    p.package_dir = Packaging::Configuration.instance.package_dir

    add_git_files p

    #don't add IDE files
    p.package_files.exclude('./nbproject')
    #don't add generated documentation. If you want have it in package, generate it fresh
    p.package_files.exclude('./doc/app')
    # ignore backups
    p.package_files.exclude('./**/*.orig')
    #ignore itself
    p.package_files.exclude('./package')
    # ignore rcov result
    p.package_files.exclude('./coverage')
    # no own database or schema
    p.package_files.exclude('./db/*.sqlite3')
    p.package_files.exclude('./db/schema.rb')
    # no logs
    p.package_files.exclude('./**/*.log')
  end
end

# this is just a dummy package task which creates the real Rake::PackageTask
# when it is invoked - this avoids removing of the old package and
# calling 'git ls-files' for every rake call (even 'rake -T')
desc "Build distribution package (no check, for testing only)"
task :"package-local" do
  # start from scratch, ensure that the package is fresh
  package_clean

  begin
    # create the real package task
    create_package_task

    # execute the real package task
    config = Packaging::Configuration.instance
    Rake::Task[File.join(config.package_dir,package_file_name+".tar.bz2")].invoke
  ensure
    # remove the package dir, not needed anymore
    remove_package_dir
  end
end

# define the same tasks as in Rake::PackageTask
desc "Remove package products"
task :clobber_package do
  remove_old_package
end

task :clobber => :clobber_package

desc "Force a rebuild of the package files"
# Note: 'repackage' can be simply redirected to 'package', the old package
# is always removed before creating a new package
task :repackage => :package

# vim: ft=ruby
