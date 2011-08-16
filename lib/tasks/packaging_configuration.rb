#FIXME use namespace
class PackagingConfiguration
  include Singleton

  def initialize
    @excluded_files = []
  end

  attr_writer :package_name, :package_dir, :version
  attr_accessor :excluded_files

  def package_name
    @package_name ||= Dir.pwd.split("/").last
  end

  def package_dir
    @package_dir ||= "package"
  end

  def version
    return @version if version
    # try find version file
    versions = Dir.glob("**/[vV][eE][rR][sS][iI][oO][nN]") #glob ignore CASEFOLD so use universal regex
    return @version = `cat #{versions.first}` unless versions.empty?
    raise "cannot find version" #TODO more heuristic
  end

  def self.run
    yield PackagingConfiguration.instance
  end
end
