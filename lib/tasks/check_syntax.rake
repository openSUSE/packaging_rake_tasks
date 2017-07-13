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
begin
  require 'parallel'
rescue LoadError
  module Parallel
    def self.each(enum, options = {}, &block)
      enum.each(&block)
    end
  end
end

namespace :check do
  desc "Check syntax of all Ruby (*.rb) files"
  task :syntax do
    puts "* Starting syntax check..." if verbose

    # check all *.rb files
    files = Dir.glob("**/*.rb")
    Parallel.each(files) do |file|
      # skip rspec files as it is not pure ruby scripts and ruby -c failed
      begin
        next unless File.readlines(file, $\, :encoding => "UTF-8").grep(/^#!.*rspec/).empty?
      rescue ArgumentError => e
        if e.to_s =~ /invalid byte sequence/
          raise e, e.message + "; offending file: #{file}"
        end
        raise
      end

      res = `ruby -c -w #{file}`
      res = res.lines.reject { |s| s == "Syntax OK\n" }.join ""
      puts res unless res.empty?
      raise "Syntax error found in file '#{file}'" unless $?.exitstatus.zero?
    end

    puts "* Done" if verbose
  end
end
