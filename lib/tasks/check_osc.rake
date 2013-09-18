#--
# Copyright (C) 2009-2013 Novell, Inc.
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
  desc "Check for installed osc client and its configuration"
  task :osc do
    puts "* Starting osc check..." if verbose

    `which osc`
    if $?.exitstatus != 0
      raise "osc client is not installed. Please run:\nsudo zypper in osc"
    end

    obs_api = Packaging::Configuration.instance.obs_api
    command_to_set_osc = "osc -A #{obs_api}"

    osc_rc = File.expand_path("~/.oscrc")
    if !File.exists? osc_rc
      raise "missing ~/.oscrc file, please run:\n#{command_to_set_osc}"
    end

    `grep -c '\[#{obs_api}\]' #{osc_rc}`
    if $?.exitstatus != 0
      "osc doesn't have set password for '#{obs_api}'." +
        " Please run:\n#{command_to_set_osc}"
    end

    puts "* Done. Everything looks good." if verbose
  end
end
