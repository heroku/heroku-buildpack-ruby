# Opens up the class of the Rails7 language pack and
# overwrites methods defined in `language_pack/test/ruby.rb` or `language_pack/test/rails2.rb`
class LanguagePack::Rails7
  # Rails removed the db:schema:load_if_ruby and `db:structure:load_if_sql` tasks
  # they've been replaced by `db:schema:load` instead
  def db_prepare_test_rake_tasks
    ["db:schema:load", "db:migrate"].map { |name| rake.task(name) }
  end
end
