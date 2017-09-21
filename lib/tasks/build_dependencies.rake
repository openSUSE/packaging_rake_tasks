#--
# Yast rake
#
# Copyright (C) 2017 SUSE LLC
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

require "shellwords"
require "open3"

namespace :build_dependencies do
  def buildrequires
    buildrequires = []

    config = Packaging::Configuration.instance
    Dir.glob("#{config.package_dir}/*.spec").each do |spec_file|
      # get the BuildRequires from the spec files, this also expands the RPM macros like %{rubygem}
      # use Open3 as the command produces some bogus error messages on stderr even on success,
      # but in case of error it provides a hint what failed
      stdout, stderr, status = Open3.capture3("rpmspec", "-q", "--buildrequires", spec_file)

      raise "Parsing #{spec_file} failed:\n#{stderr}" unless status.success?

      buildrequires.concat(stdout.split("\n"))
    end

    # remove the duplicates and sort the packages for easier reading
    buildrequires.uniq!
    buildrequires.sort!

    buildrequires
  end

  desc "Print the packages required for building"
  task :list do
    puts buildrequires.join(" ")
  end

  desc "Install the packages required for building"
  task :install do
    escaped_list = buildrequires.map { |b| Shellwords.escape(b) }.join(" ")

    if escaped_list.empty?
      puts "Nothing to install, *.spec file not found or no build dependencies defined"
    else
      cmd = "sudo zypper install #{escaped_list}"
      sh(cmd)
    end
  end
end
