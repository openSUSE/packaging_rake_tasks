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
require "shellwords"

def package_file_name
  config = Packaging::Configuration.instance
  "#{config.package_name}-#{config.version}"
end

def package_file_path
  File.join(Dir.pwd,Packaging::Configuration.instance.package_dir,
      package_file_name+".tar.bz2")
end

def remove_old_packages
  # remove the old tarball - all versions
  config = Packaging::Configuration.instance
  package_glob = File.join(Dir.pwd,config.package_dir,"#{config.package_name}-*.tar.bz2")
  verbose(verbose == true) do
    Dir[package_glob].each do |d|
      rm d
    end
  end
end

# add all GIT files under the current directory to the package_task
def add_git_files(package_task)
  # package only the files which are available in the GIT repository
  filelist = `git ls-files . | grep -v \\.gitignore`.split("\n")

  raise "currently supported is only files in git repository." unless $?.exitstatus.zero?

  # add ./ prefix so the exclude patterns match
  filelist.map! { |f| "./#{f}"}

  package_task.package_files.include filelist
end

# create new package task
def create_package_task
  require 'rake/packagetask'
  config = Packaging::Configuration.instance
  # this will just export (copy/link) the files to the target directory,
  # no tarball created
  Rake::PackageTask.new(config.package_name, config.version) do |p|
    p.package_dir = Packaging::Configuration.instance.package_dir

    add_git_files p

    config.include_files.each { |f| p.package_files.include f }
    #ignore itself
    p.package_files.exclude "./#{p.package_dir}"

    config.exclude_files.each { |f| p.package_files.exclude f }
  end
end

# this is just a dummy package task which creates the real Rake::PackageTask
# when it is invoked - this avoids removing of the old package and
# calling 'git ls-files' for every rake call (even 'rake -T')
desc "Build tarball of git repository"
task :tarball do
  # start from scratch, ensure that the package is fresh
  remove_old_packages

  # create the real package task
  create_package_task

  # execute the real package task
  config = Packaging::Configuration.instance
  target = File.join(config.package_dir, package_file_name)
  begin
    puts "* Making a tarball..." if verbose
    # collapse the middle state to false to silence FileUtils
    verbose(verbose == true) do
      Rake::Task[target].invoke
      build_tarball
    end
    puts "* ...Done" if verbose
  ensure
    verbose(verbose == true) do
      rm_rf target
    end
  end
end

# build the tarball in a reproducible way to have the very same output (bitwise)
# when called later again and also make the build machine (environmnet) independent
def build_tarball
  # set the file time stamps according to the latest commit
  mtime = `git show -s --format=%ci`.chomp
  # For the reproducible output:
  # - sort the files (in a locale independent way, use the NULL separator to
  #   correctly process also the file names containing a new line)
  #   Note: tar >= 1.28 supports "--sort=name" option, unfortunately
  #   Leap 42.3 and SLES12-SP3 contain version 1.27.1
  # - use the GNU format (the default POSIX format contains some time stamps)
  # - set the owner and group to "root"
  # - set the fixed modification time
  sh("cd #{Shellwords.escape(Packaging::Configuration.instance.package_dir)} && " \
    "find #{Shellwords.escape(package_file_name)} -xtype f -print0 | LC_ALL=C sort -z | " \
    "tar -c -j -f #{Shellwords.escape(package_file_name)}.tar.bz2 --format=gnu " \
    "--owner=root --group=root --mtime=#{Shellwords.escape(mtime)} --null --files-from -")
end

# vim: ft=ruby
