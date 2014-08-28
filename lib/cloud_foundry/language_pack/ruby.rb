class LanguagePack::Ruby < LanguagePack::Base
  alias_method :original_setup_profiled, :setup_profiled

  def setup_profiled
    original_setup_profiled

    set_env_default  "LD_LIBRARY_PATH", "$HOME/ld_library_path"
  end
end
