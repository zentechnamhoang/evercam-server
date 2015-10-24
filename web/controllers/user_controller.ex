defmodule EvercamMedia.UserController do
  use EvercamMedia.Web, :controller

  def create(conn, %{ "user" => user_params, "key" => share_key }) do
    user_changeset = User.changeset(%User{}, user_params)
    handle_user_signup(conn, user_changeset, share_key)
  end

  def create(conn, %{ "user" => user_params }) do
    user_changeset = User.changeset(%User{}, user_params)
    handle_user_signup(conn, user_changeset)
  end

  def update(conn, %{ "id" => id, "user" => user_params }) do
    user = Repo.get!(User, id)
    user_changeset  = User.changeset(user, user_params)

    case Repo.update(user_changeset) do
      {:ok, user} ->
        conn
        |> put_status(:ok)
        |> put_resp_header("access-control-allow-origin", "*")
        |> render("user.json", %{ user: user, token: nil })
      {:error, changeset} ->
        handle_error(conn, 400, changeset)
    end
  end

  defp handle_user_signup conn, user_changeset, key \\ nil do
    case user_changeset
         |> EvercamMedia.UserSignup.set_api_keys
         |> EvercamMedia.UserSignup.set_confirmed_at(key)
         |> EvercamMedia.UserSignup.create
    do
      { :invalid_user, changeset } ->
        handle_error(conn, :bad_request, changeset)
      { :duplicate_user,  changeset } ->
        handle_error(conn, :conflict, changeset)
      { :invalid_token, changeset } ->
        handle_error(conn, :unprocessable_entity, changeset)
      { :success, user, token } ->
        if key, do: EvercamMedia.UserMailer.confirm(user, key)
        conn
        |> put_status(:created)
        |> put_resp_header("access-control-allow-origin", "*")
        |> render("user.json", %{ user: user, token: token })
    end
  end

  defp handle_error(conn, status, changeset) do
    conn
    |> put_status(status)
    |> put_resp_header("access-control-allow-origin", "*")
    |> render(EvercamMedia.ChangesetView, "error.json", changeset: changeset)
  end
end
