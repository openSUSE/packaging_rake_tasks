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
# License along with this library; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "packaging/configuration"

def check_doc_output
  ENV["LANG"] = "C"
  puts "Generating documentation..." if verbose
  result = `yardoc`
  if $?.exitstatus != 0
    raise "yardoc failed"
  end

  puts result if verbose

  lines = result.lines

  warn_lines = lines.grep(/\[warn\]:/)
  if !warn_lines.empty?
    raise "There are #{warn_lines.size} warning/-s in yardoc output"
  end

  coverage_line = lines.grep(/% documented/).first
  if !coverage_line
    raise "Sorry, output format of yardoc changed. Please report issue for packaging rake tasks "\
      " and include output of your yardoc and its version"
  end

  coverage = coverage_line[/(\d+\.?\d*)% documented/, 1].to_f
  if coverage < Packaging::Configuration.instance.documentation_minimal
    raise "Too low documentation coverage #{coverage}%."
  end
end

def check_doc
  if !File.exist?(".yardopts")
    puts ".yardopts not found, skipping documentation check"
    return
  end

  if !system("which", "yardoc")
    raise "yardoc not found"
  end

  check_doc_output
end

namespace "check" do
  desc "Check for errors in documentation and minimal coverage (supported: rubydoc)"
  task :doc do
    check_doc
  end
end
