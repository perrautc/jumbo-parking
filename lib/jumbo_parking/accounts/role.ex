defmodule JumboParking.Accounts.Role do
  @moduledoc """
  Role constants and permission helpers for team member access control.

  ## Role Hierarchy
  - superadmin: Full access + manage team members
  - admin: Full access to parking operations (customers, lots, spaces, pricing)
  - staff: View-only access to dashboard and data
  """

  @superadmin "superadmin"
  @admin "admin"
  @staff "staff"

  @all_roles [@superadmin, @admin, @staff]

  @doc """
  Returns all valid roles.
  """
  def all_roles, do: @all_roles

  @doc """
  Returns the superadmin role constant.
  """
  def superadmin, do: @superadmin

  @doc """
  Returns the admin role constant.
  """
  def admin, do: @admin

  @doc """
  Returns the staff role constant.
  """
  def staff, do: @staff

  @doc """
  Returns true if the role is valid.
  """
  def valid_role?(role), do: role in @all_roles

  @doc """
  Returns true if the role can manage parking operations (customers, lots, spaces, pricing).
  Superadmin and admin roles can manage operations.
  """
  def can_manage_operations?(role) when role in [@superadmin, @admin], do: true
  def can_manage_operations?(_role), do: false

  @doc """
  Returns true if the role can manage team members.
  Only superadmin can manage team.
  """
  def can_manage_team?(role) when role == @superadmin, do: true
  def can_manage_team?(_role), do: false

  @doc """
  Returns true if the user has at least staff-level access (can view admin pages).
  All roles can view.
  """
  def can_view_admin?(role) when role in @all_roles, do: true
  def can_view_admin?(_role), do: false

  @doc """
  Returns a human-readable label for the role.
  """
  def label(@superadmin), do: "Superadmin"
  def label(@admin), do: "Admin"
  def label(@staff), do: "Staff"
  def label(_), do: "Unknown"

  @doc """
  Returns role options for select forms as {value, label} tuples.
  """
  def role_options do
    [
      {@superadmin, "Superadmin"},
      {@admin, "Admin"},
      {@staff, "Staff"}
    ]
  end
end
