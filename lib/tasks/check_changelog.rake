#--
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
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

namespace "check" do
  desc "Checking for new IDs (bugzilla,fate,...) in *.changes file"
  task :changelog do
    if obs_sr_project.nil?
      $stderr.puts "Skipping the check because OBS submit request project "\
        "is not defined (obs_sr_project)."
      next
    end
    begin
      checkout
      copy_sources

      puts "Checking IDs in *.changes file" if verbose
      # Checking makes only sense if the version in the *.spec file has been changed
      if version_changed?( "#{osc_checkout_dir}/#{package_name}.spec" )
        Dir.chdir(osc_checkout_dir) do
          # Tags described in https://github.com/openSUSE/osc-plugin-factory/blob/e12bc02e9817277335ce6adaa8e8d334d03fcc5d/check_tags_in_requests.py#L63
          cmd = "osc -A '#{obs_api}' cat '#{obs_sr_project}' '#{package_name}' "\
            "'#{package_name}.changes' | diff - '#{package_name}.changes'"
          puts cmd if verbose
          ret = `bash -c '#{cmd}'`
          unless ret.match(/(bnc|fate|boo|bsc|bgo)#[0-9]+/i) || ret.match(/cve-[0-9]{4}-[0-9]+/i)
            raise "Stopping, missing new bugzilla or fate entry in the *.changes file.\n"\
              "e.g. bnc#<number>, fate#<number>, boo#<number>, bsc#<number>, bgo#<number>, cve-<number>"
          end
        end
      else
        puts "=> do not check for IDs in *.changes file"
      end
    ensure
      cleaning
    end
  end
end
