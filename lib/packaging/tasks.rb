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

require 'rake'


module Packaging
  class Tasks

    # a flag - load the tasks just once, multiple loading
    # leads to multiple invocation of the same task
    @@tasks_loaded = false

    # load webservice *.rake files, exclude/include list can be specified
    def self.loadTasks(params = {:include => ["*.rake"], :exclude => []})
      return if @@tasks_loaded
      params[:exclude] ||= []
      params[:include] ||= ["*.rake"]
      filelist = {}

      [:exclude,:include].each do |key|
        filelist[key] = params[key].reduce([]) {|ret,file| ret += Dir["#{File.dirname(__FILE__)}/../tasks/#{file}"] }
      end

      # load an include file only if it not in the exclude list
      filelist[:include].each do |ext|
        load ext unless filelist[:exclude].include?(ext)
      end

      @@tasks_loaded = true
    end
  end
end

# vim: ft=ruby
