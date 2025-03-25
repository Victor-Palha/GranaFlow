defmodule GranaFlowWeb.CustomSubtypeController do
  use GranaFlowWeb, :controller

  alias GranaFlow.Services

  def create(conn, %{"custom_subtype" => custom_subtype_params}) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    custom_subtype_params =
      Map.new(name: custom_subtype_params)
      |> Map.put(:user_id, user_id)

    case Services.CustomSubtype.create_custom_subtype(custom_subtype_params) do
      {:ok, _custom_subtype} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Subtipo criado com sucesso."})

      {:error, %Ecto.Changeset{errors: [user_id: {"has already been taken", _}]}} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            message: "Você já possui um subtipo com este nome.",
            suggestion: "Utilize um nome diferente ou edite o subtipo existente."
          })

      {:error, %Ecto.Changeset{} = changeset} ->
          errors = translate_errors(changeset)

          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            message: "Erro ao criar subtipo",
            errors: errors
          })
    end
  end

  @spec all(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def all(conn, _params) do
    %{id: user_id} = Guardian.Plug.current_resource(conn)

    custom_subtypes =
      Services.CustomSubtype.list_user_custom_subtypes(user_id)
      |> Enum.map(fn c -> Map.from_struct(c) |> Map.delete(:__meta__) |> Map.delete(:user) end)

    conn
    |> put_status(:ok)
    |> json(%{custom_subtypes: custom_subtypes})
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
