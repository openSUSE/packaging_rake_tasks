# Packaging Rake Tasks

This is 'packaging-rake-tasks' Ruby gem package.

This gem contains useful tasks for packaging, checking and building with build service.


# Quick Start

For quick start just add

    require "packaging"

    Packaging::Configuration.run do |conf|
      conf.obs_project = "<obs_devel_project>"
      conf.package_name = "<package_name>"
    end

to your Rakefile. All shared tasks will be found and loaded automatically,
you can verify it with 'rake -T' command.

Checking if defaults fits your needs is recommended and change it if needed.

# Documentation
## Online Fresh Generated
Is available at
[rubydoc.info](http://rubydoc.info/github/openSUSE/packaging_tasks/master/frames)

## Explanation of provided tasks

TODO

# How-To

## How to remove task

If there is task that doesn't make sense for you, then you can exclude it from
loading.

To do it, replace line with

    require "packaging"


and use instead (to exclude package task e.g.)

    require 'packaging/tasks'
    Packaging::Tasks.loadTasks(:exclude => ["package.rake"])


To remove package that is used also as dependency like license check, you need
to remove it also from such dependencies

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
