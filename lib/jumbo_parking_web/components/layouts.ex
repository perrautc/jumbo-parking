defmodule JumboParkingWeb.Layouts do
  @moduledoc """
  Layouts for the Jumbo Parking application.
  """
  use JumboParkingWeb, :html

  import JumboParkingWeb.ParkingComponents

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    {render_slot(@inner_block)}
    """
  end

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite" class="fixed top-4 right-4 z-[100]">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="Connection lost"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect...
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect...
      </.flash>
    </div>
    """
  end
end
