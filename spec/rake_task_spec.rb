require_relative 'spec_helper'

describe "Rake Task" do
  it "should deploy ruby 1.8.7 without the rake gem" do
    Hatchet::AnvilApp.new("mri_187_no_rake").deploy do |app|
      expect(app.output).not_to include("Asset precompilation completed")
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should deploy ruby 1.8.7 without a Rakefile" do
    Hatchet::AnvilApp.new("mri_187_no_rakefile").deploy do |app|
      expect(app.output).not_to include("Asset precompilation completed")
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should deploy ruby 2.0.0 without a Rakefile" do
    Hatchet::AnvilApp.new("mri_200_no_rakefile").deploy do |app|
      expect(app.output).not_to include("Asset precompilation completed")
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should deploy ruby 2.0.0 with a Rakefile" do
    Hatchet::AnvilApp.new("mri_200_rakefile").deploy do |app|
      expect(app.output).not_to include("Asset precompilation completed")
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should deploy ruby 2.0.0 with assets:precompile" do
    Hatchet::AnvilApp.new("mri_200_assets").deploy do |app|
      expect(app.output).to include("Asset precompilation completed")
      expect(successful_body(app)).to eq("hello")
    end
  end

  it "should deploy ruby 2.0.0 and run assets:precompile even with logging messages" do
    Hatchet::AnvilApp.new("mri_200_logger_output").deploy do |app|
      expect(app.output).to include("Asset precompilation completed")
      expect(successful_body(app)).to eq("hello")
    end
  end
end
