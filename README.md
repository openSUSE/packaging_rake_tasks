
This is 'packaging\_rake\_tasks' Ruby gem package based on webyast rake task.

This gem contains few useful tasks for packaging and building with build service.


Loading shared tasks in other packages
--------------------------------------

Just add

    require "packaging/tasks"

line to your Rakefile. All shared tasks will be found and loaded automatically,
you can verify it with 'rake -T' command.

There is required some basic configuration for your project, especially if you don't use basic targets. For all options see class packaging/configuration.
Example of configuration ( from this gem itself )
    Packaging::Configuration.run do |conf|
    conf.obs_project = "devel:languages:ruby:extensions"
  conf.package_name = "rubygem-packaging_rake_tasks"
end


Adding a new .rake file
-----------------------

Simply put the *.rake file to lib/tasks subdirectory.


How to override a shared task
-----------------------------

Rake cannot simply change a task or rename it. If you need to redefine a shared
the best solution is to not load it at all so there is no need to redefine it.

There is a predefined class for this task, just put this your Rakefile:

    require 'lib/tasks/webservice_tasks'
    WebserviceTasks.loadTasks(:exclude => ["package.rake"])

This example loads all tasks except package task which you can define yourselves.
Wildcards are supported, use e.g. "*_check.rake" parameter to exclude all checking tasks.

On the other hand, if you want to load just one or more tasks (and ignore all other tasks) use:

    WebserviceTasks.loadTasks(:include => ["dist.rake"])

Wildcards are also supported here.

Include and exclude parameters can be combined, the excluded files have higher priority
if the same file is in both lists.


Package building
----------------

Update VERSION file if needed, then:

build package:

    rake package

clean package files:

    rake clean

clean all generated files:

    rake clobber


Installing the gem
------------------

Build the package ('rake package') and

    call 'sudo gem install packaging-rake-tasks'
   
or
    build RPM package from sources in package/ subdirectory and install it

