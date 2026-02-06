<p align="center">
  <img src="priv/static/images/logo.png" alt="Jumbo Parking & Storage" width="200">
</p>

# Jumbo Parking & Storage

A modern parking and storage management system built with Phoenix LiveView. Manage parking spaces for trucks, RVs, and cars with real-time updates and a beautiful admin dashboard.

## Features

### Public Website
- Dynamic pricing display for different vehicle types (trucks, RVs, cars)
- Online booking with Stripe Checkout payment integration
- Responsive design with dark theme

### Admin Dashboard (`/admin`)
- **Dashboard** - Overview with occupancy stats, revenue, and recent activity
- **Customers** - Manage customers, assign parking spaces, filter by status/vehicle type
- **Parking Spaces** - Visual grid of all spaces by zone, manage availability
- **Pricing** - Configure pricing plans for each vehicle type

## Tech Stack

- **Elixir 1.18+** / **Phoenix 1.8**
- **Phoenix LiveView** - Real-time UI updates
- **PostgreSQL** - Database
- **Tailwind CSS** - Styling
- **Stripe** - Payment processing via Checkout
- **Bcrypt** - Password hashing

## Getting Started

### Prerequisites

- Elixir 1.15+
- PostgreSQL
- Node.js (for assets)

### Setup

```bash
# Install dependencies
mix setup

# Start the server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) for the public site.

### Seed Data

The setup command runs seeds automatically. Default admin credentials:

- **Email:** `admin@jumboparking.com`
- **Password:** `admin123456789`

Admin panel: [`localhost:4000/admin`](http://localhost:4000/admin)

## Project Structure

```
lib/
├── jumbo_parking/           # Business logic
│   ├── accounts/            # User authentication
│   ├── parking/             # Customers, spaces, pricing, bookings
│   └── payments/            # Stripe payment integration
└── jumbo_parking_web/       # Web layer
    ├── live/
    │   ├── admin/           # Admin LiveViews
    │   ├── home_live.ex     # Public homepage
    │   └── booking_live.ex  # Booking form
    └── components/          # Reusable UI components
```

## Deployment

The project includes GitHub Actions for automated deployment. Required secrets:

- `SERVER_HOST` - Server IP/hostname
- `SERVER_USER` - SSH username
- `SSH_PRIVATE_KEY` - SSH private key

On the server, create `/var/www/jumbo-parking/.env` with:

```bash
DATABASE_URL=ecto://user:pass@localhost/jumbo_parking_prod
SECRET_KEY_BASE=your_secret_key_base
PHX_HOST=yourdomain.com
STRIPE_SECRET_KEY=sk_live_your_stripe_secret_key
```

### Stripe Configuration

For payment processing, you'll need a [Stripe account](https://stripe.com):

1. Get your API keys from the Stripe Dashboard
2. Use `sk_test_...` keys for development/testing
3. Use `sk_live_...` keys for production
4. Test payments with card number `4242 4242 4242 4242`

## License

Proprietary - All rights reserved.
