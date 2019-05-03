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


# try to keep it in sync with https://github.com/openSUSE/open-build-service/blob/master/src/api/db/seeds.rb
ID_MATCHERS = [
  /boost#(\d+)/,
  /bco#(\d+)/,
  /RT#(\d+)/,
  /CVE-(\d\d\d\d-\d+)/,
  /deb#(\d+)/,
  /fdo#(\d+)/,
  /GCC#(\d+)/,
  /bgo#(\d+)/,
  /bio#(\d+)/,
  /(?:Kernel|K|bko)#(\d+)/,
  /kde#(\d+)/,
  /b?lp#(\d+)/,
  /Meego#(\d+)/,
  /bmo#(\d+)/,
  /(?:bnc|BNC|bsc|BSC|boo|BOO)\s*[#:]\s*(\d+)/,
  /ITS#(\d+)/,
  /i#(\d+)/,
  /(?:fate|Fate|FATE)\s*#\s*(\d+)/,
  /rh#(\d+)/,
  /bso#(\d+)/,
  /sf#(\d+)/,
  /(?:bxc|Xamarin)#(\d+)/,
  /bxo#(\d+)/,
  /obs#(\d+)/,
  /build#(\d+)/,
  /osc#(\d+)/,
  /jsc#([[:alpha:]]+\-\d+)/,
]

namespace "check" do
  desc "Checking for new IDs (bugzilla,fate,...) in *.changes file"
  task :changelog => :package do
    if obs_sr_project.nil?
      $stderr.puts "Skipping the changelog check because " \
        "OBS submit request project " \
        "is not defined (obs_sr_project)." if verbose
      next
    end
    begin
      checkout
      copy_sources

      puts "Checking IDs in *.changes file" if verbose
      # Checking makes only sense if the version in the *.spec file
      # has been changed
      if version_changed?( "#{osc_checkout_dir}/#{package_name}.spec" )
        Dir.chdir(osc_checkout_dir) do
          cmd = "osc -A '#{obs_api}' cat " \
            " '#{obs_sr_project}' '#{package_name}' '#{package_name}.changes' "\
            "| diff - '#{package_name}.changes'"
          puts cmd if verbose
          ret = `bash -c '#{cmd}'`
          unless ID_MATCHERS.any?{|m| ret.match(m) }
            raise "Stopping, missing new bugzilla or fate entry " \
              "in the *.changes file.\n"\
              "e.g. bnc#<number> or fate#<number>"
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
