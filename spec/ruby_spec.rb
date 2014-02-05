require_relative 'spec_helper'

describe "Ruby apps" do
  describe "Rake detection" do
    context "Ruby 1.8.7" do
      it "doesn't run rake tasks if no rake gem" do
        Hatchet::Runner.new('mri_187_no_rake').deploy do |app, heroku|
          expect(app.output).not_to include("foo")
        end
      end

      it "runs a rake task if the gem exists" do
        Hatchet::Runner.new('mri_187_rake').deploy do |app, heroku|
          expect(app.output).to include("foo")
        end
      end
    end

    context "Ruby 1.9+" do
      it "runs rake tasks if no rake gem" do
        Hatchet::Runner.new('mri_200_no_rake').deploy do |app, heroku|
          expect(app.output).to include("foo")
        end
      end

      it "runs a rake task if the gem exists" do
        Hatchet::Runner.new('mri_200_rake').deploy do |app, heroku|
          expect(app.output).to include("foo")
        end
      end
    end
  end
end
