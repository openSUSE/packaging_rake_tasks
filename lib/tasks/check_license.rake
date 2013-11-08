#--
# Webyast Webservice framework
#
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

require "rake"
require "English" #needed for $INPUT_LINE_NUMBER

LIMIT = (ENV["LIMIT"] || 10).to_i
def license_report
  # FIXME: operate on distributed files, i.e. tarballs
  report = {:missing => [], :seen => [], :unneeded => [], :skipped => []}
  filenames = `git ls-files`.split "\n"
  filenames.each do |fn|
    next unless File.file? fn #skip all non-regular files e.g. symlinks
    # file name checks
    if fn =~ /\.yml\z/ || fn =~ /\.conf\z/ || fn =~ /\.xml\z/
      report[:skipped] << "#{fn}: skipped by name match (configuration file)"
      next
    elsif fn =~ /README/
      report[:skipped] << "#{fn}: skipped by name match (README file)"
      next
    elsif fn =~ /^db\//
      report[:skipped] << "#{fn}: skipped by name match (generated DB migration or schema)"
      next
    elsif fn =~ /licenses\//
      report[:skipped] << "#{fn}: skipped by name match (already contain license)"
      next
    elsif fn =~ /COPYING/
      report[:skipped] << "#{fn}: skipped by name match (already contain license)"
      next
    elsif fn =~ /\.changes\z/
      report[:skipped] << "#{fn}: skipped by name match (changes file)"
      next
    elsif fn =~ /\.policy\z/
      report[:skipped] << "#{fn}: skipped by name match (polkit policy file)"
      next
    elsif fn =~ /\.png\z/ || fn =~ /\.odg\z/ || fn =~ /\.gif\z/ || fn =~
        /\.swf\z/ || fn =~ /\.ico\z/ || fn =~ /\.tiff?\z/
      report[:skipped] << "#{fn}: skipped by name match (binary file)"
      next
    elsif fn =~ /\.po\z/ || fn =~ /\.mo\z/
      report[:skipped] << "#{fn}: skipped by name match (translation file)"
      next
    elsif fn =~ /\.curl\z/
      report[:skipped] << "#{fn}: skipped by name match (test fixture)"
      next
    elsif fn =~ /\.gitignore\z/
      report[:skipped] << "#{fn}: skipped by name match (version system file)"
      next
    elsif fn =~ /\.md\z/ || fn =~ /\.doc\z/ || fn =~ /\.txt\z/
      report[:skipped] << "#{fn}: skipped by name match (documentation file)"
      next
    end
    skipped = Packaging::Configuration.instance.skip_license_check.any? do |skip|
      res = fn =~ skip
      if res
        report[:skipped] << "#{fn}: skipped by name match (configuration regex)"
      end
      res
    end
    next if skipped

    # file content checks
    seen_copyright = false

    puts "Checking file: #{fn}" if verbose == true
    begin
      File.open(fn, "r") do |f|
        f.each_line do |l|
          if $INPUT_LINE_NUMBER < 3 && l =~ /Source:/
            skipped = true
            report[:skipped] << "#{fn}: skipped (external or generated source)"
            break
          end
          break if $INPUT_LINE_NUMBER > LIMIT
          if l =~ /copyright/i
            seen_copyright = true
            break
          end
        end
      end
      next if skipped
    rescue ArgumentError => e
      if e.to_s =~ /invalid byte sequence/
        raise e, e.message + "; offending file: #{fn}"
      end
      raise
    end

    if seen_copyright
      report[:seen] << "#{fn}:#{$INPUT_LINE_NUMBER}: copyright seen"
    elsif $INPUT_LINE_NUMBER <= LIMIT
      report[:unneeded] << "#{fn}:#{$INPUT_LINE_NUMBER}: copyright unneeded, file too short"
    else
      report[:missing] << "#{fn}:#{$INPUT_LINE_NUMBER}: error: copyright missing (in first #{LIMIT} lines)"
    end
  end

  if ! report[:missing].empty?
    raise "\nMissing license:\n#{report[:missing].join("\n")}"
  end
  puts "\nSkipped files:\n#{report[:skipped].join("\n")}" if verbose
  puts "\nCopyright found in these files:\n#{report[:seen].join("\n")}" if verbose
  puts "\nCopyright detected as not needed in these files:\n#{report[:unneeded].join("\n")}" if verbose
  puts "\nAll files have proper license reference." if verbose
end

namespace "check" do
  desc "Check the copyright+license headers in files"
  task :license do
    license_report
  end
end

task :package => "check:license"
