How to Release a New Version
============================

Prerequisites
-------------

1. owner of [gem on rubygems.org]
(http://rubygems.org/gems/packaging_rake_tasks)
2. write permissions in [devel:languages:ruby:extensions]
(https://build.opensuse.org/project/show/devel:languages:ruby:extensions)
Open Build Service project.

Actions
-------------

1. `rake osc:sr`
2. `gem push package/*.gem`
