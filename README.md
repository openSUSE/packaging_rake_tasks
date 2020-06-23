# Packaging Rake Tasks

This is 'packaging\_rake\_tasks' Ruby gem package.

This gem contains useful tasks for packaging, checking and building with
[Open Build Service](http://openbuildservice.org/).


# Quick Start

For a quick start just add to your Rakefile:

    require "packaging"

    Packaging.configuration do |conf|
      conf.obs_project = "<obs_devel_project>"
      conf.package_name = "<package_name>"
    end

All shared tasks will be found and loaded automatically,
you can verify it with `rake -T` command.

It is recommended to check whether the defaults fit your needs
and change the configuration if needed.

# Documentation
## Online Fresh Generated
Is available at
[rubydoc.info](http://rubydoc.info/github/openSUSE/packaging_tasks/master/frames)

## Explanation of Provided Tasks

### build_dependencies:list
Scans the `*.spec` files and prints the found `BuildRequires` dependencies.
This can be used to get the list of packages needed for building the package.

### build_dependencies:install
Similar to `build_dependencies:list` task but instead of listing them it runs
`zypper` and installs the packages. This can used to easily install the packages
which are needed for building the package.

### check:changelog
Checks if there is a supported issue tracker reference in the changelog when
version in the .spec file has been changed.

### check:commited
Checks if all changes to the local git repository are commited.
It doesn't check if changes
are sent to a remote git repository. Its main intention is to ensure that all
changes are tracked before making a package.

### check:doc
Checks if code documentation contains issues. It also checks if documentation level
is at least as high as configured in {Configuration#documentation\_minimal}.
Currently supported documentation formats: yardoc.

### check:license
Checks if all non-trivial files have a license header.
It is needed because there are
countries where implicitely everything is private unless stated otherwise
and also to help License Digger check licenses.
The check looks for a "copyright" notice or a prefix `Source:`
if the file is copied from a different source.
To skip some files use `skip_license_check` configuration option.

### check:osc
Checks if [`osc`](http://en.opensuse.org/openSUSE:OSC) is installed
and configured to allow sending to an OBS project. Its
goal is to make start of developing easier with helpful error messages.

### check:syntax
Checks syntax of all ruby files that can be found.

### osc:build
Runs local build using `osc` command. It uses separate build roots for each
basesystem for more efficient caching.

An optional argument is passed as options to `osc` and can be used to prefer
local packages: `rake "osc:build[-p /var/tmp/YaST:Head/openSUSE_Factory]"`

### osc:commit
Commit current state of git tree to OBS devel project. It runs all checks and create package.

### osc:sr
Creates a submit request to the target OBS project
(specified with `obs_sr_project` configuration option).
That includes running `osc:commit`.

### osc:sr:force
Creates a submit request from the development project to the target OBS
project.
It doesn't run anything else than `osc sr <params>`.

### package
Creates source files for building. It includes running all checks, tests and
creating a tarball.

### tarball
Creates a tarball of the local git repository without development files.

# How-To

## How to Remove a Task

If there is a task that doesn't make sense for you then you can exclude it from
loading.

For example, to exclude the `package` task, replace the `require`

    require "packaging"

with

    require "packaging/tasks"
    Packaging::Tasks.load_tasks(:exclude => ["package.rake"])

To remove check that is used also as dependency for e.g. package, it is needed
to remove it also from prerequisites of task. Example how to remove
check:license and do not call it when creating package.

    require "packaging/tasks"
    Packaging::Tasks.load_tasks(:exclude => ["check_license.rake"])
    Rake::Task["package"].prerequisites.delete("check:license")


## How to Add a New Check for Package
When a project requires a specific check before making a package
then implement it and add it to `package` as dependency:

    namespace :check do
      desc "Check for Y3K compliance"
      task :y3k do
         ...
      end
    end
    task :package => "check:y3k"

# Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# License
This package is licensed under
[LGPL-2.1](http://www.gnu.org/licenses/lgpl-2.1.html).
