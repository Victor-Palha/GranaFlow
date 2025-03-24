defmodule GranaFlow.Guardian do
  use Guardian, otp_app: :grana_flow

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    {:ok, %{id: claims["sub"]}}
  end

  def generate_token(user, "main") do
    claims = %{
      "typ" => "main",
      "exp" => Guardian.timestamp() + 600, # 10 minutes
      "premium" => user.premium
    }

    encode_and_sign(user, claims, token_type: "main")
  end

  def generate_token(user, "refresh") do
    claims = %{
      "typ" => "refresh",
      "exp" => Guardian.timestamp() + 60 * 60 * 24 * 30 # 30 days
    }

    encode_and_sign(user, claims, token_type: "refresh")
  end
end
