# frozen_string_literal: true

module Noosh24
  class Resource
    def initialize(client)
      @client = client
    end

    def inspect
      "#<#{self.class.name}>"
    end

    private

    def path_id(value)
      raise ArgumentError, "An id is required" unless value.is_a?(String) && !value.strip.empty?

      Client.escape(value)
    end

    def list_query(limit:, offset:, sort:, where:, expand: nil)
      query = {}
      query["limit"] = Integer(limit) unless limit.nil?
      query["offset"] = Integer(offset) unless offset.nil?
      sorts = strings(sort)
      query["sort"] = sorts unless sorts.empty?
      text = where.to_s
      query["where"] = text unless text.empty?
      expands = strings(expand)
      query["expand"] = expands unless expands.empty?
      query
    end

    def strings(value)
      Array(value).map(&:to_s).reject(&:empty?)
    end

    def fetch_page(path, model, query)
      _, data = @client.request("GET", path, query: query)
      data = Convert.mapping(data)
      items = Convert.list_of(data["items"], model)
      Page.new(
        items: items,
        total: Convert.int(data["total"]) || items.size,
        limit: Convert.int(data["limit"]) || query.fetch("limit", items.size),
        offset: Convert.int(data["offset"]) || query.fetch("offset", 0)
      )
    end

    def paginate(path, model, query, page_size, &block)
      query = { "limit" => page_size, "offset" => 0 }.merge(query)
      enum = Enumerator.new do |yielder|
        cursor = query.dup
        loop do
          page = fetch_page(path, model, cursor)
          page.items.each { |item| yielder << item }
          break unless page.has_more?

          cursor["offset"] = page.next_offset
        end
      end
      return enum unless block

      enum.each(&block)
      nil
    end

    def fetch_all(path, model)
      _, data = @client.request("GET", path)
      Convert.list_of(Convert.mapping(data)["items"], model)
    end

    def fetch_one(path, model, query = nil)
      _, data = @client.request("GET", path, query: query)
      model.from_hash(data)
    end
  end

  class Menu < Resource
    def list_categories
      fetch_all("/menu/categories", Category)
    end

    def list_products(limit: nil, offset: nil, sort: nil, where: nil, expand: nil)
      fetch_page("/menu/products", Product, list_query(limit:, offset:, sort:, where:, expand:))
    end

    def iterate_products(limit: nil, offset: nil, sort: nil, where: nil, expand: nil, &)
      page_size = strings(expand).empty? ? 100 : 50
      paginate("/menu/products", Product, list_query(limit:, offset:, sort:, where:, expand:), page_size, &)
    end

    def get_product(product_id, expand: nil)
      expands = strings(expand)
      fetch_one("/menu/products/#{path_id(product_id)}", Product, expands.empty? ? nil : { "expand" => expands })
    end

    def get_stop_list
      fetch_all("/menu/stop-list", StopListItem)
    end
  end

  class Reservations < Resource
    def list(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/reservations", Reservation, list_query(limit:, offset:, sort:, where:))
    end

    def iterate(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/reservations", Reservation, list_query(limit:, offset:, sort:, where:), 100, &)
    end

    def get(reservation_id)
      fetch_one("/reservations/#{path_id(reservation_id)}", Reservation)
    end

    def availability(date, time, guests: nil)
      query = { "date" => Convert.date_param(date), "time" => time, "guests" => guests }
      fetch_one("/reservations/availability", TableAvailability, query)
    end

    def create(reservation = nil, **fields)
      booking = NewReservation.coerce(reservation.nil? ? fields : reservation)
      status, data = @client.request("POST", "/reservations", body: booking.to_body, retryable: booking.idempotent?)
      CreateReservationResult.new(reservation: Reservation.from_hash(data), created: status == 201)
    end

    def cancel(reservation_id)
      _, data = @client.request("POST", "/reservations/#{path_id(reservation_id)}/cancel")
      Reservation.from_hash(data)
    end
  end

  class Orders < Resource
    def list(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/orders", Order, list_query(limit:, offset:, sort:, where:))
    end

    def iterate(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/orders", Order, list_query(limit:, offset:, sort:, where:), 100, &)
    end

    def get(order_id)
      fetch_one("/orders/#{path_id(order_id)}", Order)
    end

    def list_bills(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/bills", Bill, list_query(limit:, offset:, sort:, where:))
    end

    def iterate_bills(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/bills", Bill, list_query(limit:, offset:, sort:, where:), 50, &)
    end

    def get_bill(bill_id)
      fetch_one("/bills/#{path_id(bill_id)}", Bill)
    end
  end

  class Payments < Resource
    def list(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/payments", Payment, list_query(limit:, offset:, sort:, where:))
    end

    def iterate(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/payments", Payment, list_query(limit:, offset:, sort:, where:), 100, &)
    end

    def get(payment_id)
      fetch_one("/payments/#{path_id(payment_id)}", Payment)
    end

    def z_report(date = nil)
      _, data = @client.request("GET", "/reports/z", query: date.nil? ? nil : { "date" => Convert.date_param(date) })
      Convert.mapping(data)
    end
  end

  class Tables < Resource
    def list
      fetch_all("/tables", Table)
    end

    def list_halls
      fetch_all("/halls", Hall)
    end
  end

  class Customers < Resource
    def list(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/customers", Customer, list_query(limit:, offset:, sort:, where:))
    end

    def iterate(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/customers", Customer, list_query(limit:, offset:, sort:, where:), 100, &)
    end

    def get(customer_id)
      fetch_one("/customers/#{path_id(customer_id)}", Customer)
    end
  end

  class Loyalty < Resource
    def get_program
      fetch_one("/loyalty/program", LoyaltyProgram)
    end

    def list_cards(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/loyalty/cards", LoyaltyCard, list_query(limit:, offset:, sort:, where:))
    end

    def iterate_cards(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/loyalty/cards", LoyaltyCard, list_query(limit:, offset:, sort:, where:), 100, &)
    end
  end

  class Stock < Resource
    def list_ingredients(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/stock/ingredients", Ingredient, list_query(limit:, offset:, sort:, where:))
    end

    def iterate_ingredients(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/stock/ingredients", Ingredient, list_query(limit:, offset:, sort:, where:), 100, &)
    end

    def list_moves(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/stock/moves", StockMove, list_query(limit:, offset:, sort:, where:))
    end

    def iterate_moves(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/stock/moves", StockMove, list_query(limit:, offset:, sort:, where:), 100, &)
    end

    def list_stores
      fetch_all("/stock/stores", StockStore)
    end
  end

  class Reviews < Resource
    def list(limit: nil, offset: nil, sort: nil, where: nil)
      fetch_page("/reviews", Review, list_query(limit:, offset:, sort:, where:))
    end

    def iterate(limit: nil, offset: nil, sort: nil, where: nil, &)
      paginate("/reviews", Review, list_query(limit:, offset:, sort:, where:), 100, &)
    end
  end
end
