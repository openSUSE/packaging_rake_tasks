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

require 'rake'
require "tempfile"
require "tmpdir"

namespace :osc do

  def obs_project
    Packaging::Configuration.instance.obs_project
  end

  def obs_sr_project
    Packaging::Configuration.instance.obs_sr_project
  end

  def package_name
    Packaging::Configuration.instance.package_name
  end

  def package_dir
    Packaging::Configuration.instance.package_dir
  end

  def build_dist
    Packaging::Configuration.instance.obs_target
  end

  def cleaning
    rm_rf obs_project
    puts "cleaning" if verbose
  end

  def obs_api
    Packaging::Configuration.instance.obs_api
  end

  def checkout
    osc_verbose = (verbose == true) ? "--verbose" : ""
    sh "osc -A '#{obs_api}' --traceback #{osc_verbose} checkout '#{obs_project}' #{package_name}"
  end

  def osc_checkout_dir
    File.join(Dir.pwd, obs_project, package_name)
  end

  def copy_sources
    # clean project to easily add/remove new/old ones
    Dir["#{osc_checkout_dir}/*"].each do |d|
      rm d
    end
    # copy new
    Dir["#{package_dir}/*"].each do |f|
      cp f, osc_checkout_dir
    end

    Dir.chdir(osc_checkout_dir) do
      sh "osc -A '#{obs_api}' addremove"
    end
  end

  def version_changed? updated_spec_file
    begin
      file = Tempfile.new('yast-rake')
      file.close
      sh "osc -A '#{obs_api}' cat '#{obs_sr_project}' '#{package_name}' '#{package_name}.spec' > #{file.path}" do |ok, res|
        if !ok
          puts "Version cannot be compared, so act like it is different" if verbose
          return true
        end
      end
      original_version = version_from_spec(file.path)
      new_version      = version_from_spec(updated_spec_file)

      if new_version == original_version
        puts "Version has not been changed in *.spec file" if verbose
        return false
      else
        puts "Version has been changed in *.spec file" if verbose
        return true
      end
    ensure
      file.unlink if file
    end
  end

  def version_from_spec spec_glob
    version = `grep '^Version:' #{spec_glob}`
    version.sub!(/^Version:\s*/, "")
    version.sub!(/#.*$/, "")
    version.strip!
    version
  end

  def different_tarballs?(source1, source2)
    return true if !File.exist?(source1) || !File.exist?(source2)

    Dir.mktmpdir("unpacked_tarball") do |d1|
      sh "tar xvf #{source1} -C #{d1}"

      Dir.mktmpdir("unpacked_tarball") do |d2|
        sh "tar xvf #{source2} -C #{d2}"

        res = `diff -ur #{d1} #{d2}`
        puts res if verbose

        return !$?.success?
      end
    end
  end

  def check_changes!
    # run spec file service to ensure that just formatting changes is not detected
    Dir.chdir(package_dir) { sh "/usr/lib/obs/service/format_spec_file --outdir ." }
    Dir["#{package_dir}/*"].each do |f|
      orig = f.sub(/#{package_dir}\//, "")
      if orig =~ /\.(tar|tbz2|tgz|tlz)/ # tar archive, so ignore archive creation time otherwise it always looks like new one
        return if different_tarballs?(f, File.join(osc_checkout_dir, orig))
      else
        cmd = "diff -u #{f} #{osc_checkout_dir}/#{orig}"
        puts cmd if verbose
        puts `bash -c '#{cmd}'`

        return unless $?.success? # there is something new
      end
    end

    puts "Stop commiting, no difference from devel project"
    exit 0
  end

  desc "Build package locally"
  task :build, [:osc_options] => ["check:osc", "package"] do |t, args|
    args.with_defaults = { :osc_options => "" }
    raise "Missing information about your Build service project" if !build_dist || !obs_project || !package_name

    begin
      checkout
      copy_sources
      puts "Building package #{package_name} from project #{obs_project}" if verbose

      pkg_dir = File.join("/var/tmp", obs_project, build_dist)
      mkdir_p pkg_dir
      Dir.chdir osc_checkout_dir do
        puts "building package..." if verbose

        # pipe yes to osc build to automatic rebuild broken build root if it happen
        command = "yes | osc -A '#{obs_api}' build"
        command << " --no-verify" #ignore untrusted BS projects
        command << " --release=1" #have always same release number
        # store packages for given base system at one place, so it speeds up rebuild
        command << " --keep-pkgs=#{pkg_dir}"
        command << " #{args[:osc_options]}"
        command << " #{build_dist}"

        sh command
      end
    ensure
      cleaning
    end
  end

  MAX_CHANGES_LINES = 20
  desc "Commit package to devel project in build service if sources are correct and build"
  task :commit => "osc:build" do
    begin
      checkout
      # check that there is some changes, otherwise it exit
      check_changes!
      copy_sources

      Dir.chdir osc_checkout_dir do
        puts "submitting package..." if verbose
        # Take new lines from changes and use it as commit message.
        # If a line starts with +, delete + and print it.
        # Except skip the added "-----" header and the timestamp-author after that,
        # and skip the +++ diff header
        changes = `osc -A '#{obs_api}' diff *.changes | sed -n '/^+---/,+2b;/^+++/b;s/^+//;T;p'`.strip
        if changes.empty?
          # %h is short hash of a commit
          git_ref = `git log --format=%h -n 1`.chomp
          changes = "Updated to git ref #{git_ref}"
        end

        # provide only reasonable amount of changes
        changes = changes.split("\n").take(MAX_CHANGES_LINES).join("\n")

        sh "osc", "-A", obs_api, "commit", "-m", changes
        puts "New package submitted to #{obs_project}" if verbose
      end
    ensure
      cleaning
    end
  end

  desc "Create submit request from updated devel project to target project if version change."
  task :sr => ["check:changelog", "osc:commit"] do
    begin
      checkout
      unless version_changed?( "#{package_dir}/#{package_name}.spec" )
        puts "=> no submit request" if verbose
      else
        Rake::Task["osc:sr:force"].execute
      end
    ensure
      cleaning
    end
  end

  namespace "sr" do
    desc "Create submit request from devel project to target project without any other packaging or checking"
    task :force do
      # wait for the server service to finish to avoid "service in progress"
      # error when creating a SR for a freshly commited package
      puts "Waiting for the server side service..."
      sh "osc", "-A", obs_api, "service", "wait", obs_project, package_name

      new_version = version_from_spec("#{package_dir}/#{package_name}.spec")
      if Packaging::Configuration.instance.maintenance_mode
        sh "yes | osc -A '#{obs_api}' maintenancerequest --no-cleanup '#{obs_project}' '#{package_name}' '#{obs_sr_project}' -m 'submit new version #{new_version}'"
      else
        sh "yes | osc -A '#{obs_api}' submitreq --no-cleanup '#{obs_project}' '#{package_name}' '#{obs_sr_project}' -m 'submit new version #{new_version}' --yes"
      end
    end
  end
end
