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

### Merch Store (`/store`)
- Browse merchandise with product variants (size/color)
- Session-based shopping cart
- Secure checkout with Stripe payments
- Dual fulfillment: Printful (print-on-demand) and in-stock items
- Order tracking and confirmation

### Admin Dashboard (`/admin`)
- **Dashboard** - Overview with occupancy stats, revenue, and recent activity
- **Customers** - Manage customers, assign parking spaces, filter by status/vehicle type
- **Parking Spaces** - Visual grid of all spaces by zone, manage availability
- **Pricing** - Configure pricing plans for each vehicle type
- **Merch** - Manage products with variants, fulfillment settings, and inventory
- **Orders** - View and manage store orders, process fulfillment, update status

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
│   ├── payments/            # Stripe payment integration
│   ├── store/               # E-commerce (carts, orders, variants)
│   └── fulfillment/         # Order fulfillment (Printful integration)
└── jumbo_parking_web/       # Web layer
    ├── live/
    │   ├── admin/           # Admin LiveViews
    │   ├── store/           # Merch store LiveViews
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
PRINTFUL_API_KEY=your_printful_api_key  # Optional: for print-on-demand fulfillment
```

### Stripe Configuration

For payment processing, you'll need a [Stripe account](https://stripe.com):

1. Get your API keys from the Stripe Dashboard
2. Use `sk_test_...` keys for development/testing
3. Use `sk_live_...` keys for production
4. Test payments with card number `4242 4242 4242 4242`

### Printful Configuration (Optional)

For print-on-demand merchandise fulfillment:

1. Create a [Printful account](https://www.printful.com)
2. Get your API key from Settings > API
3. Set `PRINTFUL_API_KEY` in your environment
4. Mark products as "printful" fulfillment type in admin
5. Configure webhook URL: `https://yourdomain.com/webhooks/printful`

## License

Proprietary - All rights reserved.
