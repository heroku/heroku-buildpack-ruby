require_relative '../spec_helper'

describe "cnb" do
  it "locally" do
    run!("which pack")

    repo_path = hatchet_path("heroku/ruby-getting-started")
    image_name = "heroku-buildpack-ruby-tests:#{SecureRandom.hex}"

    build_out = run!("pack build #{image_name} --path #{repo_path} --buildpack #{buildpack_path} --builder heroku/buildpacks:18")
    expect(build_out).to match("Compiling Ruby/Rails")

    run_out = run!("docker run #{image_name} 'ruby -v'").chomp
    expect(run_out).to match("2.4.4")
  ensure
    if image_name
      docker_list = run("docker images | grep #{image_name}").chomp
      run!("docker rmi #{image_name}") if !docker_list.empty?
    end
  end
end

