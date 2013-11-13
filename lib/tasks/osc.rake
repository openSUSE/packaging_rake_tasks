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

namespace :osc do

  def obs_project
    Packaging::Configuration.instance.obs_project
  end

  def obs_sr_project
    Packaging::Configuration.instance.obs_sr_project
  end

  def package_name
    Packaging::Configuration.instance.package_name
  end

  def package_dir
    Packaging::Configuration.instance.package_dir
  end

  def build_dist
    Packaging::Configuration.instance.obs_target
  end

  def cleaning
    rm_rf obs_project
    puts "cleaning" if verbose
  end

  def obs_api
    Packaging::Configuration.instance.obs_api
  end

  def checkout
    sh "osc -A '#{obs_api}' --traceback --verbose checkout '#{obs_project}' #{package_name}"
  end

  def osc_checkout_dir
    File.join(Dir.pwd, obs_project, package_name)
  end

  def copy_sources
    # clean project to easily add/remove new/old ones
    Dir["#{osc_checkout_dir}/*"].each do |d|
      rm d
    end
    # copy new
    Dir["#{package_dir}/*"].each do |f|
      cp f, osc_checkout_dir
    end

    Dir.chdir(osc_checkout_dir) do 
      sh "osc addremove"
    end
  end

  def version_from_spec spec_glob
    version = `grep '^Version:' #{spec_glob}`
    version.sub! /^Version:\s*/, ""
    version.sub! /#.*$/, ""
    version.strip!
    version
  end

  desc "Build package locally"
  task :build, [:osc_options] => ["check:osc", "package"] do |t, args|
    args.with_defaults = { :osc_options => "" }
    raise "Missing information about your Build service project" if !build_dist || !obs_project || !package_name

    begin
      checkout
      copy_sources
      puts "Building package #{package_name} from project #{obs_project}" if verbose

      pkg_dir = File.join("/var/tmp", obs_project, build_dist)
      mkdir_p pkg_dir
      Dir.chdir osc_checkout_dir do
        puts "building package..." if verbose

        command = "osc build"
        command << " --no-verify" #ignore untrusted BS projects
        command << " --release=1" #have always same release number
        # have separated roots per target system, so sharing is more effficient
        command << " --root=/var/tmp/build-root-#{build_dist}"
        # store packages for given base system at one place, so it spped up rebuild
        command << " --keep-pkgs=#{pkg_dir}"
        command << " #{args[:osc_options]}"
        command << " #{build_dist}"

        sh command
      end
    ensure
      cleaning
    end
  end

  desc "Commit package to devel project in build service if sources are correct and build"
  task :commit => "osc:build" do
    begin
      checkout
      copy_sources

      Dir.chdir osc_checkout_dir do
        puts "submitting package..." if verbose
        # Take new lines from changes and use it as commit message.
        # If a line starts with +, delete + and print it.
        # Except skip the added "-----" header and the timestamp-author after that,
        # and skip the +++ diff header
        changes = `osc diff *.changes | sed -n '/^+---/,+2b;/^+++/b;s/^+//;T;p'`.strip
        if changes.empty?
          # %h is short hash of a commit
          git_ref = `git log --format=%h -n 1`.chomp
          changes = "Updated to git ref #{git_ref}"
        end

        sh "osc", "commit", "-m", changes
        puts "New package submitted to #{obs_project}" if verbose
      end
    ensure
      cleaning
    end
  end

  desc "Create submit request from updated devel project to target project if version change."
  task :sr => "osc:commit" do
    begin
      checkout

      original_version = version_from_spec("#{osc_checkout_dir}/*.spec")
      new_version      = version_from_spec("#{package_dir}/*.spec")

      if new_version == original_version
        puts "No version change => no submit request" if verbose
      else
        Rake::Task["osc:sr:force"].execute
      end
    ensure
      cleaning
    end
  end

  namespace "sr" do
    desc "Create submit request from devel project to target project without any other packaging or checking"
    task :force do
      new_version = version_from_spec("#{package_dir}/*.spec")
      sh "osc -A '#{obs_api}' sr '#{obs_project}' '#{package_name}' '#{obs_sr_project}' -m 'submit new version #{new_version}'"
    end
  end
end
