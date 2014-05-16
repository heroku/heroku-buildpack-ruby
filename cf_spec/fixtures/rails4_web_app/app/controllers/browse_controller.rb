class BrowseController < ApplicationController
  def show
    path = "/#{params[:path]}"
    path += ".#{params[:format]}" if params[:format]

    begin
      if File.directory? path
        @dir = Dir.new(path)
        render
      else
        render :text => File.open(path).readlines.join("\n")
      end
    rescue Errno::ENOENT => e
      render text: "Failed with error: #{e}"
    end
  end
end