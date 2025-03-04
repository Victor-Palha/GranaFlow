defmodule GranaFlow.Guardian do
  use Guardian, otp_app: :grana_flow

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    {:ok, %{id: claims["sub"]}}
  end
end
