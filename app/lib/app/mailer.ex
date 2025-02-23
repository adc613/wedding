defmodule App.Mailer do
  use Swoosh.Mailer, otp_app: :app

  def get_from_email() do
    Application.fetch_env!(:app, :from_email)
  end
end
