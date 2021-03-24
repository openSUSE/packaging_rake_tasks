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


namespace :check do
  desc "check if everything is committed to git repository"
  task :committed do
    if ENV["COMMIT_CHECK"] == "0" || ENV["COMMIT_CHECK"] == "false"
      puts "WARNING: Skipping Git commit check!"
      next
    end

    ignored = `git ls-files -o --exclude-standard .`

    raise "git ls-files failed." unless $?.exitstatus.zero?

    if ! ignored.empty?
      raise "New files missing in git (or add them to to .gitignore):\n#{ignored}\n\n"
    end

    modified = `git ls-files -m --exclude-standard .`

    raise "git ls-files failed." unless $?.exitstatus.zero?

    if ! modified.empty?
      raise "Modified files not committed:\n#{modified}"
    end
  end
end
