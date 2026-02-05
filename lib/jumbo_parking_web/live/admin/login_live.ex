defmodule JumboParkingWeb.Admin.LoginLive do
  use JumboParkingWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Admin Login")
      |> assign(:form, to_form(%{"email" => "", "password" => ""}, as: "user"))
      |> assign(:show_password, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_password", _params, socket) do
    {:noreply, assign(socket, :show_password, !socket.assigns.show_password)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black flex items-center justify-center p-4">
      <div class="w-full max-w-md">
        <!-- Logo -->
        <div class="text-center mb-8">
          <a href="/" class="inline-flex items-center gap-3">
            <img src={~p"/images/logo.png"} alt="Jumbo Parking" class="h-12 w-auto" />
            <span class="text-white font-bold text-2xl">Jumbo Parking</span>
          </a>
          <p class="text-[#a0a0a0] mt-2">Admin Panel</p>
        </div>

        <!-- Login Form -->
        <div class="bg-[#1a1a1a] border border-[#333333] rounded-2xl p-8">
          <h2 class="text-2xl font-bold text-white mb-2">Welcome Back</h2>
          <p class="text-[#a0a0a0] text-sm mb-8">Sign in to your admin account</p>

          <div :if={Phoenix.Flash.get(@flash, :error)} class="mb-4 p-3 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
            {Phoenix.Flash.get(@flash, :error)}
          </div>
          <div :if={Phoenix.Flash.get(@flash, :info)} class="mb-4 p-3 rounded-lg bg-green-500/10 border border-green-500/20 text-green-400 text-sm">
            {Phoenix.Flash.get(@flash, :info)}
          </div>

          <form action={~p"/admin/login"} method="post" class="space-y-6">
            <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token_for("/admin/login")} />

            <div>
              <label class="block text-sm text-[#a0a0a0] mb-1.5">Email</label>
              <input type="email" name="user[email]" value={@form.params["email"]} required
                class="w-full bg-[#111111] border border-[#333333] rounded-lg px-4 py-3 text-white placeholder-[#666] focus:border-[#c8d935] focus:ring-1 focus:ring-[#c8d935] outline-none transition-colors"
                placeholder="admin@jumboparking.com" />
            </div>

            <div>
              <label class="block text-sm text-[#a0a0a0] mb-1.5">Password</label>
              <div class="relative">
                <input type={if @show_password, do: "text", else: "password"} name="user[password]" required
                  class="w-full bg-[#111111] border border-[#333333] rounded-lg px-4 py-3 text-white placeholder-[#666] focus:border-[#c8d935] focus:ring-1 focus:ring-[#c8d935] outline-none transition-colors pr-12"
                  placeholder="Enter your password" />
                <button type="button" phx-click="toggle_password" class="absolute right-3 top-1/2 -translate-y-1/2 text-[#a0a0a0] hover:text-white transition-colors">
                  <svg :if={!@show_password} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  <svg :if={@show_password} xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                  </svg>
                </button>
              </div>
            </div>

            <button type="submit" class="w-full bg-[#c8d935] hover:bg-[#b5c52e] text-black font-semibold py-3 rounded-lg transition-colors">
              Sign In
            </button>
          </form>
        </div>

        <p class="text-center text-[#a0a0a0] text-sm mt-6">
          <.link navigate={~p"/"} class="hover:text-[#c8d935] transition-colors">&larr; Back to website</.link>
        </p>
      </div>
    </div>
    """
  end
end
