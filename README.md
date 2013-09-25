# Packaging Rake Tasks

This is 'packaging\_rake\_tasks' Ruby gem package.

This gem contains useful tasks for packaging, checking and building with [build
service](http://openbuildservice.org/).


# Quick Start

For quick start just add to your Rakefile.

    require "packaging"

    Packaging::Configuration.run do |conf|
      conf.obs_project = "<obs_devel_project>"
      conf.package_name = "<package_name>"
    end

All shared tasks will be found and loaded automatically,
you can verify it with 'rake -T' command.

Checking if defaults fits your needs is recommended and change it if needed.

# Documentation
## Online Fresh Generated
Is available at
[rubydoc.info](http://rubydoc.info/github/openSUSE/packaging_tasks/master/frames)

## Explanation of provided tasks

### check:commited
Checks if all changes to git repository is commited. It doesn't check if changes
are send to remote git repository. It main intention is to ensure, that all
changes are tracked before making package.

### check:license
Checks if all non-trivial file have license header. It is needed because there
is countries where implicitelly everything is private unless stated otherwise
and also to help license digger check licenses. Check recognize license or
prefix `Source:` if file is copyied from different source.
To skip some files use `skip_license_check` configuration option.

### check:osc
Checks if osc is installed and configured to allow sending to OBS project. Its
goal is to make start of developing easier with helpful error messages.

### check:syntax
Checks syntax of all ruby files that can be found.

### osc:build
Runs local build using osc command. Use separate temporary files for each
basesystem for more efficient caching.

### osc:commit
Commit recent version to OBS devel project. It runs all checks and create recent
package.

### osc:sr
Create submit request to target OBS project specified with `obs_sr_project`
configuration option. Task include running `osc:commit`.

### osc:sr:force
Create submit request from devel project to target OBS project. Do not runs
anything else then `osc sr <params>`.

### package
Create source files for build. It includes running all checks, tests and
creating tarball.

### tarball
Creates tarball of git repository without development files.

# How-To

## How to remove task

If there is task that doesn't make sense for you, then you can exclude it from
loading.

To do it, replace line with

    require "packaging"


and use instead (to exclude package task e.g.)

    require 'packaging/tasks'
    Packaging::Tasks.loadTasks(:exclude => ["package.rake"])


To remove check that is used also as dependency for e.g. package, it is needed
to remove it also from prerequisites of task. Example how to remove
check:license and do not call it when creating package.

    require 'packaging/tasks'
    Packaging::Tasks.loadTasks(:exclude => ["check_license.rake"])
    Rake::Task["package"].prerequisites.delete("check:license")


## How to Add New Check For Package
When project require specific check before making package, then implement it and
it to package as dependency:

    task :example do
      ...
    end
    task :package => :example

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# License
Package is licensed by LGPL-2.1.
