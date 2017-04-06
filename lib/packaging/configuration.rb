#--
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

module Packaging

  def self.configuration &block
    yield Configuration.instance
  end

  class Configuration
    include Singleton

    def initialize
      @exclude_files = []
      @include_files = []
      @obs_api = "https://api.opensuse.org/"
      @obs_target = "openSUSE_Factory"
      @skip_license_check = []
      @maintenance_mode = false
      @check_documentation = false
      @documentation_minimal = 0
    end

    #custom package name, by default directory name
    attr_writer :package_name
    #custom directory where is package created, by default 'package'
    attr_writer :package_dir
    #manul version specification,  by default look for file version (case insensitive)
    attr_writer :version
    # array of files excluded for packaging
    attr_accessor :exclude_files
    # array of files included for packaging (useful for e.g. for generated file not in git
    # @note recommended way is to generate in spec and not before package
    # @example generate css from sass (where sass:update is task to generate it)
    #   Packaging::Configuration.instance.include_files './**/*.css'
    #   Rake::Task(:'package-local').prerequisites << "sass:update"
    attr_accessor :include_files
    # project name in OBS
    attr_accessor :obs_project
    # Project name in BS where submit request should go
    attr_accessor :obs_sr_project
    # path to OBS api, useful if package is build in own instance of build service. By default api.opensuse.org
    attr_accessor :obs_api
    # obs build target, by default opensuse factory
    attr_accessor :obs_target
    # additional list of regex to skip license check
    attr_accessor :skip_license_check
    # Specify if project is in maintenance mode. If so, then it create maintenance request instead of pull request
    attr_accessor :maintenance_mode
    # Minimal documentation coverage to pass check:doc
    # Default value is 0.
    attr_accessor :documentation_minimal

    def package_name
      @package_name ||= Dir.pwd.split("/").last
    end

    def package_dir
      @package_dir ||= "package"
    end

    def version
      return @version if @version
      # try find version file
      versions = Dir.glob("version", File::FNM_CASEFOLD)
      return @version = File.read(versions.first).strip unless versions.empty?
      raise "cannot find version" #TODO more heuristic
    end
  end
end
