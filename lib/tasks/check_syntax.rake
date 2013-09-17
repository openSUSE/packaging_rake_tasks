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

namespace :check do
  desc "Check syntax of all Ruby (*.rb) files"
  task :syntax do
    puts "* Starting syntax check..." if verbose

    # check all *.rb files
    Dir.glob("**/*.rb").each do |file|
      res = `ruby -c #{file}`
      puts "#{file}: #{res}" if verbose
      raise "Syntax error found in file '#{file}'" unless $?.exitstatus.zero?
    end

    puts "* Done" if verbose
  end
end
