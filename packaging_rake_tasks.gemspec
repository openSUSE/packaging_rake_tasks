#--
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


Gem::Specification.new do |spec|

# gem name and description
spec.name	= "packaging_rake_tasks"
spec.version	= File.read(File.expand_path("../VERSION", __FILE__)).chomp
spec.summary	= "Rake tasks providing tasks to package project in git and integration with build service"
spec.license    = "LGPL-2.1"

# author
spec.author	= "Josef Reidinger"
spec.email	= "jreidinger@suse.cz"
spec.homepage	= "https://github.com/openSUSE/packaging_rake_tasks"

spec.description = "Rake tasks to allow easy packaging ruby projects in git for Build Service or other packaging service"

# gem content
spec.files   = Dir["lib/**/*.rb", "lib/tasks/*.rake", "COPYING", "VERSION"]

# define LOAD_PATH
spec.require_path = "lib"

# dependencies
spec.add_dependency("rake")
end
