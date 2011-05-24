Rails::Application.configure do
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
end
