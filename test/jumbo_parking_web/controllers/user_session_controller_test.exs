defmodule JumboParkingWeb.UserSessionControllerTest do
  use JumboParkingWeb.ConnCase, async: true

  import JumboParking.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "POST /admin/login" do
    test "logs the user in with valid credentials", %{conn: conn, user: user} do
      user = set_password(user)

      conn =
        post(conn, ~p"/admin/login", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/admin"
    end

    test "redirects back to login with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/admin/login", %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      assert redirected_to(conn) == ~p"/admin/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
    end
  end

  describe "DELETE /admin/logout" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/admin/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/admin/logout")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
