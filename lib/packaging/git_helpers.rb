#--
# Rake helpers
#
# Copyright (C) 2019 SUSE Linux LLC
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
  #
  # Helpers around various git commands
  module GitHelpers
    # Create a git tag based on the version and the current branch.
    #
    # The optional block can specify the version number to use.  If no block
    # is given, this uses spec_version, i.e. the version number of the first
    # .spec file in the package/ subdirectory.
    #
    # @return [Boolean] true if the tag was created, false if it already existed
    #
    def create_version_tag(&block)
      name = tag_name(&block)
      if tag_exists?(name)
        puts "Tag #{name} already exists"
        false
      else
        puts "Creating tag #{name}"
        git("tag #{name}")
        true
      end
    end

    # Check if a tag exists.
    #
    # @return Boolean
    #
    def tag_exists?(name = nil)
      name ||= tag_name
      git("tag").include?(name)
    end

    # Read the package version from the first .spec file in the packages/
    # subdirectory.
    #
    # @return String
    #
    def spec_version
      # use the first *.spec file found, assume all spec files
      # contain the same version
      File.readlines(Dir.glob("package/*.spec").first)
          .grep(/^\s*Version:\s*/).first.sub("Version:", "").strip
    end

    # Return the name of the current git branch or "detached" if in "head
    # detached" state.
    #
    # @return String
    #
    def branch_name
      branch = git("branch").grep(/^\* /).first.sub(/^\* /, "")
      return "detached" if branch =~ /HEAD detached/
      branch
    end

    # Check if the current branch is "master".
    #
    # @return [Boolean]
    #
    def master?
      branch_name == "master"
    end

    # Return a suitable tag name based on version and branch.
    # For "master", this is only the version number.
    # For branches, this is "branchname-version".
    # If in "detached head" state, this is "detached-version".
    #
    # Like in create_version_tag, the optional block can specify the version
    # number to use. If no block is given, this uses spec_version, i.e. the
    # version number of the first .spec file in the package/ subdirectory.
    #
    # @return String
    #
    def tag_name(&block)
      branch = branch_name
      version = block_given? ? block.call : spec_version
      return version if branch == "master"
      branch + "-" + version
    end

    # Call a git subcommand and return its output as an array of strings.
    #
    # @return Array<String>
    #
    def git(subcmd)
      `/usr/bin/git #{subcmd}`.split("\n")
    end
  end
end
