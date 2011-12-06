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
  class Configuration
    include Singleton

    def initialize
      @excluded_files = []
      @obs_api = "https://api.opensuse.org/"
      @obs_target = "openSUSE_Factory"
    end

    #custom package name, by default directory name
    attr_writer :package_name
    #custom directory where is package created, by default 'package'
    attr_writer :package_dir
    #manul version specification,  by default look for file version (case insensitive)
    attr_writer :version
    # array of files excluded for packaging
    attr_accessor :excluded_files
    # project name in OBS
    attr_accessor :obs_project
    # path to OBS api, useful if package is build in own instance of build service. By default api.opensuse.org
    attr_accessor :obs_api
    # obs build target, by default opensuse factory
    attr_accessor :obs_target

    def package_name
      @package_name ||= Dir.pwd.split("/").last
    end

    def package_dir
      @package_dir ||= "package"
    end

    def version
      return @version if @version
      # try find version file
      versions = Dir.glob("**/[vV][eE][rR][sS][iI][oO][nN]") #glob ignore CASEFOLD so use universal regex
      return @version = `cat #{versions.first}`.chomp unless versions.empty?
      raise "cannot find version" #TODO more heuristic
    end

    def self.run
      yield instance
    end
  end
end
