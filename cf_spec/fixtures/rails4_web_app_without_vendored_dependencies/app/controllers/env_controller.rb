class EnvController < ApplicationController
  def show
    @env = `env`
  end
end
