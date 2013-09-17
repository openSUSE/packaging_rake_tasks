namespace :check do
  desc "check if everything is commited to git repository"
  task :commited do
    ignored = `git ls-files -o .`

    raise "git ls-files failed." unless $?.exitstatus.zero?

    if ! ignored.empty?
      raise "Files missing in git and not in .gitignore: #{ignored.join("\n")}"
    end

    modified = `git ls-files -m .`

    raise "git ls-files failed." unless $?.exitstatus.zero?

    if ! modified.empty?
      raise "Modified files not commited: #{ignored.join("\n")}"
    end
  end
end
