[![CircleCI](https://circleci.com/gh/nebulab/solidus_afterpay.svg?style=shield)](https://circleci.com/gh/nebulab/solidus_afterpay)
[![codecov](https://codecov.io/gh/nebulab/solidus_afterpay/branch/main/graph/badge.svg)](https://codecov.io/gh/solidusio/solidus_afterpay)
# Solidus Afterpay

<!-- Explain what your extension does. -->
> [!IMPORTANT] 
> This gem still depends on the legacy [solidus_frontend](https://github.com/solidusio/solidus_frontend) gem being available in the Solidus application.

## Installation

Add solidus_afterpay to your Gemfile:

```ruby
gem 'solidus_afterpay'
```

Bundle your dependencies and run the installation generator:

```shell
bin/rails generate solidus_afterpay:install
```

## Basic Setup

### Retrieve Afterpay account details

You'll need the following account details:

- `Merchant ID`
- `Secret key`

These values can be obtained by calling the `Merchant Support` [here](https://developers.afterpay.com/afterpay-online/docs/merchant-support).

### Create a new payment method

Payment methods can accept preferences either directly entered in admin, or from a static source in code. For most projects we recommend using a static source, so that sensitive account credentials are not stored in the database.

1. Set static preferences in an initializer

```ruby
# config/initializers/spree.rb
Spree::Config.configure do |config|
  config.static_model_preferences.add(
    SolidusAfterpay::PaymentMethod,
    'afterpay_credentials', {
      merchant_id: ENV['AFTERPAY_MERCHANT_ID'],
      secret_key: ENV['AFTERPAY_SECRET_KEY'],
      test_mode: ENV.fetch('AFTERPAY_ENVIRONMENT', '') != 'production'
    }
  )
end
```

2. Visit `/admin/payment_methods/new`
3. Set `provider` to SolidusAfterpay::PaymentMethod
4. Click "Save"
5. Choose `afterpay_credentials` from the `Preference Source` select
6. Click `Update` to save

Alternatively, create a payment method from the Rails console with:

```ruby
SolidusAfterpay::PaymentMethod.new(
  name: "Afterpay",
  preference_source: "afterpay_credentials"
).save
```

## Deferred Payment Flow

This flow completes the payment approval and starts the consumer's payment plan, but does not initiate the settlement process. This flow allows settlement of merchant funds to be deferred until order fulfilment can be confirmed.

Simply set the auto_capture to false when creating the Afterpay payment_method to activate the deferred payment flow instead of the immediate payment flow.

For more info about the deferred payment flow click [here](https://developers.afterpay.com/afterpay-online/reference#deferred-payment-flow).

## Usage

### Customizing shipping rate builder

By default, the extension will build the shipping rates based on the default Solidus shipments building the Afterpay array.

If you want to override this logic, you can provide your own `shipping_rate_calculator_class`.

### Customizing update order attributes service

By default, the extension will update the order payment_attributes, order email attribute and shipments attributes based on the Afterpay returned data.

If you want to override this logic, adding/removing attributes, you can provide your own `update_order_attributes_service_class`.

### Express checkout from the cart

An Afterpay button can also be included on the cart view to enable express checkouts:

```ruby
<%= render "solidus_afterpay/afterpay_checkout_button" %>
```

### Afterpay Messaging

Afterpay offers an on-site messaging component to notify the customer that there are financing options available.

To add the `Afterpay messaging` simply add the `Afterpay messaging partial` into your `html.erb` file, like this.

You need to provide the products as well, so you can exclude products from `Afterpay messaging`. It is required to
add the product in an array for example: `products: [<product>]`, or for multiple products: `products: [<product1>, <product2>]`.

If you only have the order you can do it like this `products: order.line_items.map { |item| item.variant.product }`.

```erb
<%= render "spree/shared/afterpay_messaging", min: nil, max: nil, products: [<Product>], data: { amount: <Product price>, locale: "en_US", currency: "USD" } %>
```

The amount, locale and currency are required in order to work properly.

This will automatically render an Afterpay messaging icon.

The max attribute is to configure till which amount Afterpay should be available.

The min attribute is to configure from which amount Afterpay should be available.

For example if you would write...

```erb
<%= render "spree/shared/afterpay_messaging", min: nil, max: 25, products: [<Product>], data: { amount: <Product price>, locale: "en_US", currency: "USD" } %>
```

And a product price is `28.99`, Afterpay will display on that product that Afterpay is only available for orders between 1$ and 25$.

The default value for min is 1$.

When adding nil to `max`, Afterpay will be available on all orders.

Click [here](https://developers.afterpay.com/afterpay-online/docs/advanced-usage) for more information on how to configure/style Afterpay messaging.

If you would like to change the size of the Afterpay messaging you simply add size to the `data` hash. For example...

```erb
<%= render "spree/shared/afterpay_messaging", min: nil, max: nil, product: [<Product>], data: { amount: <Product price>, locale: "en_US", currency: "USD", size: "sm" } %>
```

## Development

### Testing the extension

First bundle your dependencies, then run `bin/rake`. `bin/rake` will default to building the dummy
app if it does not exist, then it will run specs. The dummy app can be regenerated by using
`bin/rake extension:test_app`.

```shell
bin/rake
```

To run [Rubocop](https://github.com/bbatsov/rubocop) static code analysis run

```shell
bundle exec rubocop
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your `spec/spec_helper.rb`:

```ruby
require 'solidus_afterpay/testing_support/factories'
```

Or, if you are using `FactoryBot.definition_file_paths`, you can load Solidus core
factories along with this extension's factories using this statement:

```ruby
SolidusDevSupport::TestingSupport::Factories.load_for(SolidusAfterpay::Engine)
```

### Running the sandbox

To run this extension in a sandboxed Solidus application, you can run `bin/sandbox`. The path for
the sandbox app is `./sandbox` and `bin/rails` will forward any Rails commands to
`sandbox/bin/rails`.

Here's an example:

```
$ bin/rails server
=> Booting Puma
=> Rails 6.0.2.1 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```

### Updating the changelog

Before and after releases the changelog should be updated to reflect the up-to-date status of
the project:

```shell
bin/rake changelog
git add CHANGELOG.md
git commit -m "Update the changelog"
```

### Releasing new versions

Please refer to the dedicated [page](https://github.com/solidusio/solidus/wiki/How-to-release-extensions) on Solidus wiki.

## License

Copyright (c) 2021 Afterpay Corporate Services Pty Ltd, released under the Apache License, Version 2.0
