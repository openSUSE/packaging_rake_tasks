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

RPM_SOURCE_DIR = "/usr/src/packages/SOURCES/"
desc "Build rpms with rpmbuild, no source check"
task :'buildrpm-local' => :'package-local' do
 Dir.chdir 'package' do
  #copy sources to proper directory
  files = Dir["*"].select{ |s| File.file?(s) || File.symlink?(s) }
  specs = files.select { |f| f =~ /\.spec$/i }
  raise "No spec file found" if specs.empty?  
  spec = specs.first
  files.delete(spec)
  begin
    files.each { |f| cp f,RPM_SOURCE_DIR }
    sh "rpmbuild", "-bb", spec
  ensure
    files.each { |f| rm File.join(RPM_SOURCE_DIR,f)}
  end
 end
end

desc "Build rpm with rpmbuild"
task :buildrpm => [ :check_syntax, :git_check, :'buildrpm-local']


