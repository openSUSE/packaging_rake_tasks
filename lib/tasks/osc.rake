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

  def package_name
    Packaging::Configuration.instance.package_name
  end

  def build_dist
    Packaging::Configuration.instance.build_dist
  end

  def cleaning
    rm_rf obs_project
    puts "cleaning" if verbose
  end

  def checkout
    obs_api = Packaging::Configuration.instance.obs_api
    sh "osc -A '#{obs_api}' -tv checkout '#{obs_project}' #{package_name}"
  end

  def copy_sources
    #clean project to easily add/remove new/old ones
    Dir["#{obs_project}/#{package_name}/*"].each do |d|
      rm d
    end
    #copy new
    Dir["package/*"].each do |f|
      cp f,"#{obs_project}/#{package_name}"
    end
  end

  desc "Build package locally"
  task :build => "package" do
    raise "Missing information about your Build service project" if !build_dist || !obs_project || !package_name

    checkout
    copy_sources
    puts "Building package #{package_name} from project #{obs_project}" if verbose

    pkg_dir = File.join("/var/tmp", obs_project, build_dist)
    mkdir_p pkg_dir
    begin
      Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
        puts "building package..." if verbose

        sh "osc build --no-verify --release=1 --root=/var/tmp/build-root-#{build_dist} --keep-pkgs=#{pkg_dir} --prefer-pkgs=#{pkg_dir} #{build_dist}"
      end
    ensure
      cleaning
    end
  end

  desc "Submit package to devel project in build service if sources are correct and build"
  task :submit => "osc:build" do
    checkout
    copy_sources
    begin
      Dir.chdir File.join(Dir.pwd, obs_project, package_name) do
        puts "submitting package..." if verbose
        sh "osc addremove"
        changes = `osc diff *.changes | sed -n '/^+---/,+2b;/^+++/b;s/^+//;T;p'`
        sh "osc", "commit", "-m", changes
        puts "New package submitted to #{obs_project}" if verbose
      end
    ensure
      cleaning
    end
  end
end