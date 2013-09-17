namespace :check do
  desc "check if everything is commited to git repository"
  task :committed do
    ignored = `git ls-files -o .`

    raise "git ls-files failed." unless $?.exitstatus.zero?

    if ! ignored.empty?
      raise "New files missing in git and ( if false alarm, add them to .gitignore ): #{ignored}"
    end

    modified = `git ls-files -m .`

    raise "git ls-files failed." unless $?.exitstatus.zero?

    if ! modified.empty?
      raise "Modified files not commited: #{ignored}"
    end
  end
end
