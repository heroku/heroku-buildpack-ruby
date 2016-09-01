#module LanguagePack::Test::Rails2
class LanguagePack::Rails2
  # sets up the profile.d script for this buildpack
  def setup_profiled
    super
    set_env_default "RACK_ENV",  "test"
    set_env_default "RAILS_ENV", "test"
  end

  def default_env_vars
    {
      "RAILS_ENV" => "test",
      "RACK_ENV"  => "test"
    }
  end

  def rake_env
    super.merge(default_env_vars)
  end
end
