defmodule GranaFlowWeb.ProofController do
  use GranaFlowWeb, :controller
  alias GranaFlow.Utils.R2Uploader

  def create(conn, %{"proof" => %Plug.Upload{} = upload}) do
    case R2Uploader.upload_file(upload.path, upload.filename, upload.content_type) do
      {:ok, url} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Comprovante salvo com sucesso", url: url})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{error: inspect(reason)})
    end
  end
end
