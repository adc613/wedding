defmodule AppWeb.InvitationController do
  use AppWeb, :controller

  alias App.Guest.Invitation
  alias App.MyGuest

  def index(conn, _params) do
    invitations = MyGuest.list_invitations(preload: :guests)
    render(conn, :index, invitations: invitations)
  end

  def show(conn, %{"id" => id}) do
    case MyGuest.get_invitation(id, preload: :guests) do
      nil -> render_not_found(conn)
      invitation -> render(conn, :detail, invitation: invitation)
    end
  end

  def remove_guest(conn, %{"id" => id, "guest_id" => guest_id}) do
    MyGuest.get_guest!(guest_id) |> MyGuest.update!(%{"invitation_id" => nil})

    conn
    |> put_flash(:info, "Removed guest from invite")
    |> redirect(to: "/invitation/#{id}/edit")
  end

  def add_guest(conn, %{"id" => id, "guest_id" => guest_id}) do
    MyGuest.get_guest!(guest_id) |> MyGuest.update!(%{"invitation_id" => id})

    conn
    |> put_flash(:info, "Added guest to invite")
    |> redirect(to: "/invitation/#{id}/edit")
  end

  def edit(conn, %{"id" => id, "redirect" => redirect}) do
    invitation = MyGuest.get_invitation(id, preload: :guests)
    changeset = Invitation.add_form_attrs(invitation) |> Invitation.changeset()
    guests = MyGuest.list_guests()

    render(conn, :edit,
      invitation: invitation,
      changeset: changeset,
      redirect: redirect,
      all_guests: guests
    )
  end

  def edit(conn, %{"id" => id}) do
    edit(conn, %{"id" => id, "redirect" => ~p"/invitation/#{id}/edit"})
  end

  def new(conn, _params) do
    changeset = Invitation.changeset(%Invitation{})

    conn
    |> render(:new, changeset: changeset)
  end

  def create(conn, %{"invitation" => invitation_params}) do
    case MyGuest.create_invitation(invitation_params) do
      {:ok, invitation} ->
        conn
        |> put_flash(:info, "Created new Invitation")
        |> redirect(to: ~p"/invitation/#{invitation}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "invitation" => invitation_params, "redirect" => redirect}) do
    invitation = MyGuest.get_invitation!(id)
    invitation_params = Invitation.cast_form_attrs(invitation_params)

    case MyGuest.update(invitation, invitation_params) do
      {:ok, _invitation} ->
        conn
        |> put_flash(:info, "Updated invitation")
        |> redirect(to: redirect)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:error, "Failed to update invitation")
        |> render(:edit, invitation: invitation, changeset: changeset, redirect: ~p"/invitation")
    end
  end

  def update(conn, %{"id" => id, "invitation" => invitation_params}) do
    update(conn, %{
      "id" => id,
      "invitation" => invitation_params,
      "redirect" => ~p"/invitation/#{id}"
    })
  end

  def delete(conn, %{"id" => id}) do
    MyGuest.get_invitation(id)
    |> MyGuest.delete()
    |> case do
      {:ok, _invitation} -> put_flash(conn, :info, "Deleted invitation")
      {:error, _invitation} -> put_flash(conn, :error, "Failed to delete invitation")
    end
    |> redirect(to: ~p"/invitation")
  end
end
