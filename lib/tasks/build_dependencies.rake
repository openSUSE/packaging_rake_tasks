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
require "tempfile"

namespace :build_dependencies do
  # Read the multi build targets from the "_multibuild" file.
  # @return [Array<String>] list of multi build targets or empty Array if the
  #   "_multibuild" file does not exist
  def multibuild_flavors
    flavors = []

    # parse the _multibuild XML file if it is present
    mbfile = File.join(Packaging::Configuration.instance.package_dir, "_multibuild")
    if File.exist?(mbfile)
      require "rexml/document"
      doc = REXML::Document.new(File.read(mbfile))
      doc.elements.each("//multibuild/flavor | //multibuild/package") do |node|
        flavors << node.text.strip
      end
    end

    puts "Found multibuild targets: #{flavors.join(", ")}" if verbose && !flavors.empty?
    flavors
  end

  # Read the build dependencies from all spec files. For multi build packages
  # evaluate all package flavors.
  # @return [Array<String>] list of build dependencies
  def buildrequires
    buildrequires = []
    # OBS additionally runs a default build with empty flavor in multi build packages,
    # for simplification use it also for single build packages
    flavors = multibuild_flavors + [ "" ]
    Dir.glob("#{Packaging::Configuration.instance.package_dir}/*.spec").each do |spec_file|
      # replace the "@BUILD_FLAVOR@" placeholder by each flavor defined
      flavors.each do |flavor|
        spec_content = File.read(spec_file).gsub!("@BUILD_FLAVOR@", flavor)

        if spec_content.nil?
          # no replacement, use the file directly
          stdout = `rpmspec -q --buildrequires #{spec_file.shellescape}`
          raise "Parsing #{spec_file} failed" unless $?.success?
          buildrequires.concat(stdout.split("\n"))
        else
          # rpmspec can only read a file, write the processed data to a temporary file
          Tempfile.create(["rake_build_deps-", ".spec"]) do |tmp|
            tmp.write(spec_content)
            tmp.flush
            stdout = `rpmspec -q --buildrequires #{tmp.path.shellescape}`
            raise "Parsing #{spec_file} (flavor #{flavor.inspect}) failed" unless $?.success?
            buildrequires.concat(stdout.split("\n"))
          end
        end
      end
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
      sudo = Process.euid.zero? ? "" : "sudo"
      interactive = $stdin.tty? ? "" : "--non-interactive"
      # allow package downgrade to avoid failures in CI when the installed
      # packages are higher than the available ones
      cmd = "#{sudo} zypper #{interactive} install --allow-downgrade #{escaped_list}"
      sh(cmd)
    end
  end
end
