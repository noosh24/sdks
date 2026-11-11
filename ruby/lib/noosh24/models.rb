# frozen_string_literal: true

module Noosh24
  Restaurant = Data.define(
    :id,
    :name,
    :slug
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        slug: Convert.str(data["slug"]),
        raw: data
      )
    end
  end

  ApiKeyInfo = Data.define(
    :id,
    :name,
    :prefix,
    :scopes
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        prefix: Convert.str(data["prefix"]),
        scopes: Convert.strings(data["scopes"]),
        raw: data
      )
    end
  end

  Subscription = Data.define(
    :status,
    :modules
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        status: Convert.str(data["status"]),
        modules: Convert.strings(data["modules"]),
        raw: data
      )
    end
  end

  Features = Data.define(
    :loyalty,
    :inventory
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        loyalty: Convert.bool(data["loyalty"]),
        inventory: Convert.bool(data["inventory"]),
        raw: data
      )
    end
  end

  Whoami = Data.define(
    :restaurant,
    :key,
    :subscription,
    :features
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        restaurant: Convert.object(data["restaurant"], Restaurant),
        key: Convert.object(data["key"], ApiKeyInfo),
        subscription: Convert.object(data["subscription"], Subscription),
        features: Convert.object(data["features"], Features),
        raw: data
      )
    end
  end

  Category = Data.define(
    :name,
    :position,
    :products,
    :available
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        name: Convert.str(data["name"]),
        position: Convert.int(data["position"]),
        products: Convert.int(data["products"]),
        available: Convert.int(data["available"]),
        raw: data
      )
    end
  end

  Modifier = Data.define(
    :id,
    :name,
    :price_delta,
    :position
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        price_delta: Convert.float(data["priceDelta"]),
        position: Convert.int(data["position"]),
        raw: data
      )
    end
  end

  ModifierGroup = Data.define(
    :id,
    :name,
    :required,
    :position,
    :modifiers
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        required: Convert.bool(data["required"]),
        position: Convert.int(data["position"]),
        modifiers: Convert.list_of(data["modifiers"], Modifier),
        raw: data
      )
    end
  end

  ProductTranslation = Data.define(
    :name,
    :description
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        name: Convert.str(data["name"]),
        description: Convert.str(data["description"]),
        raw: data
      )
    end
  end

  Product = Data.define(
    :id,
    :name,
    :category,
    :description,
    :price,
    :available,
    :popular,
    :position,
    :prep_minutes,
    :station,
    :vat_rate,
    :vegetarian,
    :spicy,
    :allergens,
    :discountable,
    :has_modifiers,
    :image,
    :video,
    :modifier_groups,
    :translations
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        category: Convert.str(data["category"]),
        description: Convert.str(data["description"]),
        price: Convert.float(data["price"]),
        available: Convert.bool(data["available"]),
        popular: Convert.bool(data["popular"]),
        position: Convert.int(data["position"]),
        prep_minutes: Convert.int(data["prepMinutes"]),
        station: Convert.str(data["station"]),
        vat_rate: Convert.float(data["vatRate"]),
        vegetarian: Convert.bool(data["vegetarian"]),
        spicy: Convert.bool(data["spicy"]),
        allergens: Convert.strings(data["allergens"]),
        discountable: Convert.bool(data["discountable"]),
        has_modifiers: Convert.bool(data["hasModifiers"]),
        image: Convert.str(data["image"]),
        video: Convert.str(data["video"]),
        modifier_groups: Convert.list_of(data["modifierGroups"], ModifierGroup),
        translations: Convert.map_of(data["translations"], ProductTranslation),
        raw: data
      )
    end
  end

  StopListItem = Data.define(
    :id,
    :name,
    :category,
    :price
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        category: Convert.str(data["category"]),
        price: Convert.float(data["price"]),
        raw: data
      )
    end
  end

  ReservationGuest = Data.define(
    :name,
    :phone,
    :email
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        name: Convert.str(data["name"]),
        phone: Convert.str(data["phone"]),
        email: Convert.str(data["email"]),
        raw: data
      )
    end
  end

  ReservationTable = Data.define(
    :id,
    :label
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        label: Convert.str(data["label"]),
        raw: data
      )
    end
  end

  ReservationPreOrderItem = Data.define(
    :product_id,
    :name,
    :price,
    :qty,
    :note
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        product_id: Convert.str(data["productId"]),
        name: Convert.str(data["name"]),
        price: Convert.float(data["price"]),
        qty: Convert.int(data["qty"]),
        note: Convert.str(data["note"]),
        raw: data
      )
    end
  end

  Reservation = Data.define(
    :id,
    :code,
    :status,
    :source,
    :starts_at,
    :ends_at,
    :guests,
    :zone,
    :table,
    :guest,
    :special_request,
    :allergy_note,
    :birthday,
    :child_chair,
    :deposit_paid,
    :pre_order,
    :external_ref,
    :decided_at,
    :created_at,
    :updated_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        code: Convert.str(data["code"]),
        status: Convert.str(data["status"]),
        source: Convert.str(data["source"]),
        starts_at: Convert.time(data["startsAt"]),
        ends_at: Convert.time(data["endsAt"]),
        guests: Convert.int(data["guests"]),
        zone: Convert.str(data["zone"]),
        table: Convert.object(data["table"], ReservationTable),
        guest: Convert.object(data["guest"], ReservationGuest),
        special_request: Convert.str(data["specialRequest"]),
        allergy_note: Convert.str(data["allergyNote"]),
        birthday: Convert.bool(data["birthday"]),
        child_chair: Convert.bool(data["childChair"]),
        deposit_paid: Convert.float(data["depositPaid"]),
        pre_order: Convert.list_of(data["preOrder"], ReservationPreOrderItem),
        external_ref: Convert.str(data["externalRef"]),
        decided_at: Convert.time(data["decidedAt"]),
        created_at: Convert.time(data["createdAt"]),
        updated_at: Convert.time(data["updatedAt"]),
        raw: data
      )
    end
  end

  AvailableTable = Data.define(
    :id,
    :label,
    :hall_id,
    :zone,
    :seats,
    :free
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        label: Convert.str(data["label"]),
        hall_id: Convert.str(data["hallId"]),
        zone: Convert.str(data["zone"]),
        seats: Convert.int(data["seats"]),
        free: Convert.bool(data["free"]),
        raw: data
      )
    end
  end

  TableAvailability = Data.define(
    :starts_at,
    :ends_at,
    :duration_minutes,
    :open_time,
    :close_time,
    :tables
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        starts_at: Convert.time(data["startsAt"]),
        ends_at: Convert.time(data["endsAt"]),
        duration_minutes: Convert.int(data["durationMinutes"]),
        open_time: Convert.str(data["openTime"]),
        close_time: Convert.str(data["closeTime"]),
        tables: Convert.list_of(data["tables"], AvailableTable),
        raw: data
      )
    end
  end

  OrderItem = Data.define(
    :id,
    :product_id,
    :name,
    :qty,
    :price,
    :list_price,
    :modifiers,
    :note,
    :status,
    :comp,
    :campaign,
    :cancel_reason
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        product_id: Convert.str(data["productId"]),
        name: Convert.str(data["name"]),
        qty: Convert.int(data["qty"]),
        price: Convert.float(data["price"]),
        list_price: Convert.float(data["listPrice"]),
        modifiers: Convert.str(data["modifiers"]),
        note: Convert.str(data["note"]),
        status: Convert.str(data["status"]),
        comp: Convert.bool(data["comp"]),
        campaign: Convert.str(data["campaign"]),
        cancel_reason: Convert.str(data["cancelReason"]),
        raw: data
      )
    end
  end

  DeliveryPlatform = Data.define(
    :id,
    :name,
    :ref
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        ref: Convert.str(data["ref"]),
        raw: data
      )
    end
  end

  OrderDelivery = Data.define(
    :status,
    :platform,
    :address,
    :customer_phone,
    :courier_name,
    :note,
    :payment_method,
    :fee,
    :platform_total,
    :accepted_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        status: Convert.str(data["status"]),
        platform: Convert.object(data["platform"], DeliveryPlatform),
        address: Convert.str(data["address"]),
        customer_phone: Convert.str(data["customerPhone"]),
        courier_name: Convert.str(data["courierName"]),
        note: Convert.str(data["note"]),
        payment_method: Convert.str(data["paymentMethod"]),
        fee: Convert.float(data["fee"]),
        platform_total: Convert.float(data["platformTotal"]),
        accepted_at: Convert.time(data["acceptedAt"]),
        raw: data
      )
    end
  end

  Order = Data.define(
    :id,
    :number,
    :daily_number,
    :kind,
    :order_type,
    :status,
    :table_id,
    :bill_id,
    :customer_name,
    :allergy_note,
    :items,
    :subtotal,
    :delivery,
    :created_at,
    :updated_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        number: Convert.str(data["number"]),
        daily_number: Convert.int(data["dailyNumber"]),
        kind: Convert.str(data["kind"]),
        order_type: Convert.str(data["orderType"]),
        status: Convert.str(data["status"]),
        table_id: Convert.str(data["tableId"]),
        bill_id: Convert.str(data["billId"]),
        customer_name: Convert.str(data["customerName"]),
        allergy_note: Convert.str(data["allergyNote"]),
        items: Convert.list_of(data["items"], OrderItem),
        subtotal: Convert.float(data["subtotal"]),
        delivery: Convert.object(data["delivery"], OrderDelivery),
        created_at: Convert.time(data["createdAt"]),
        updated_at: Convert.time(data["updatedAt"]),
        raw: data
      )
    end
  end

  Bill = Data.define(
    :id,
    :table_id,
    :status,
    :guests,
    :waiter,
    :customer_id,
    :reservation_id,
    :order_ids,
    :subtotal,
    :discount_percent,
    :bill_discount,
    :service_fee_percent,
    :service_fee,
    :total,
    :paid,
    :remaining,
    :opened_at,
    :closed_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        table_id: Convert.str(data["tableId"]),
        status: Convert.str(data["status"]),
        guests: Convert.int(data["guests"]),
        waiter: Convert.str(data["waiter"]),
        customer_id: Convert.str(data["customerId"]),
        reservation_id: Convert.str(data["reservationId"]),
        order_ids: Convert.strings(data["orderIds"]),
        subtotal: Convert.float(data["subtotal"]),
        discount_percent: Convert.float(data["discountPercent"]),
        bill_discount: Convert.float(data["billDiscount"]),
        service_fee_percent: Convert.float(data["serviceFeePercent"]),
        service_fee: Convert.float(data["serviceFee"]),
        total: Convert.float(data["total"]),
        paid: Convert.float(data["paid"]),
        remaining: Convert.float(data["remaining"]),
        opened_at: Convert.time(data["openedAt"]),
        closed_at: Convert.time(data["closedAt"]),
        raw: data
      )
    end
  end

  PaymentCard = Data.define(
    :masked_pan,
    :scheme,
    :bank
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        masked_pan: Convert.str(data["maskedPan"]),
        scheme: Convert.str(data["scheme"]),
        bank: Convert.str(data["bank"]),
        raw: data
      )
    end
  end

  PaymentPlatform = Data.define(
    :id,
    :name
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        raw: data
      )
    end
  end

  Payment = Data.define(
    :id,
    :status,
    :method,
    :recorded_method,
    :amount,
    :tip,
    :refunded_amount,
    :refunded_at,
    :refund_reason,
    :bill_id,
    :reservation_id,
    :order_id,
    :taken_at,
    :card,
    :platform,
    :created_at,
    :settled_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        status: Convert.str(data["status"]),
        method: Convert.str(data["method"]),
        recorded_method: Convert.str(data["recordedMethod"]),
        amount: Convert.float(data["amount"]),
        tip: Convert.float(data["tip"]),
        refunded_amount: Convert.float(data["refundedAmount"]),
        refunded_at: Convert.time(data["refundedAt"]),
        refund_reason: Convert.str(data["refundReason"]),
        bill_id: Convert.str(data["billId"]),
        reservation_id: Convert.str(data["reservationId"]),
        order_id: Convert.str(data["orderId"]),
        taken_at: Convert.str(data["takenAt"]),
        card: Convert.object(data["card"], PaymentCard),
        platform: Convert.object(data["platform"], PaymentPlatform),
        created_at: Convert.time(data["createdAt"]),
        settled_at: Convert.time(data["settledAt"]),
        raw: data
      )
    end
  end

  Hall = Data.define(
    :id,
    :name,
    :position
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        position: Convert.int(data["position"]),
        raw: data
      )
    end
  end

  Table = Data.define(
    :id,
    :label,
    :hall_id,
    :zone,
    :seats,
    :shape,
    :status,
    :guests,
    :waiter,
    :seated_since,
    :open_orders,
    :bill_id,
    :bill_total,
    :bill_requested,
    :bill_settled,
    :merged_into
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        label: Convert.str(data["label"]),
        hall_id: Convert.str(data["hallId"]),
        zone: Convert.str(data["zone"]),
        seats: Convert.int(data["seats"]),
        shape: Convert.str(data["shape"]),
        status: Convert.str(data["status"]),
        guests: Convert.int(data["guests"]),
        waiter: Convert.str(data["waiter"]),
        seated_since: Convert.str(data["seatedSince"]),
        open_orders: Convert.int(data["openOrders"]),
        bill_id: Convert.str(data["billId"]),
        bill_total: Convert.float(data["billTotal"]),
        bill_requested: Convert.bool(data["billRequested"]),
        bill_settled: Convert.bool(data["billSettled"]),
        merged_into: Convert.str(data["mergedInto"]),
        raw: data
      )
    end
  end

  Customer = Data.define(
    :id,
    :name,
    :phone,
    :note,
    :created_at,
    :updated_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        phone: Convert.str(data["phone"]),
        note: Convert.str(data["note"]),
        created_at: Convert.time(data["createdAt"]),
        updated_at: Convert.time(data["updatedAt"]),
        raw: data
      )
    end
  end

  LoyaltyProgram = Data.define(
    :stamps_needed,
    :earn_by,
    :min_bill,
    :once_per_day,
    :reward_name,
    :reward_scope,
    :reward_categories,
    :reward_product_ids,
    :reward_max_price,
    :terms
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        stamps_needed: Convert.int(data["stampsNeeded"]),
        earn_by: Convert.str(data["earnBy"]),
        min_bill: Convert.float(data["minBill"]),
        once_per_day: Convert.bool(data["oncePerDay"]),
        reward_name: Convert.str(data["rewardName"]),
        reward_scope: Convert.str(data["rewardScope"]),
        reward_categories: Convert.strings(data["rewardCategories"]),
        reward_product_ids: Convert.strings(data["rewardProductIds"]),
        reward_max_price: Convert.float(data["rewardMaxPrice"]),
        terms: Convert.str(data["terms"]),
        raw: data
      )
    end
  end

  LoyaltyCard = Data.define(
    :id,
    :name,
    :phone,
    :stamps,
    :total_stamps,
    :redeemed,
    :source,
    :last_visit_at,
    :created_at,
    :updated_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        phone: Convert.str(data["phone"]),
        stamps: Convert.int(data["stamps"]),
        total_stamps: Convert.int(data["totalStamps"]),
        redeemed: Convert.int(data["redeemed"]),
        source: Convert.str(data["source"]),
        last_visit_at: Convert.time(data["lastVisitAt"]),
        created_at: Convert.time(data["createdAt"]),
        updated_at: Convert.time(data["updatedAt"]),
        raw: data
      )
    end
  end

  Ingredient = Data.define(
    :id,
    :name,
    :unit,
    :stock,
    :on_open_bills,
    :available,
    :state,
    :low_stock,
    :par_stock,
    :cost_per_unit,
    :value,
    :prepared,
    :by_store,
    :updated_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        unit: Convert.str(data["unit"]),
        stock: Convert.float(data["stock"]),
        on_open_bills: Convert.float(data["onOpenBills"]),
        available: Convert.float(data["available"]),
        state: Convert.str(data["state"]),
        low_stock: Convert.float(data["lowStock"]),
        par_stock: Convert.float(data["parStock"]),
        cost_per_unit: Convert.float(data["costPerUnit"]),
        value: Convert.float(data["value"]),
        prepared: Convert.bool(data["prepared"]),
        by_store: Convert.floats(data["byStore"]),
        updated_at: Convert.time(data["updatedAt"]),
        raw: data
      )
    end
  end

  StockStore = Data.define(
    :id,
    :name,
    :is_default,
    :stations
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        name: Convert.str(data["name"]),
        is_default: Convert.bool(data["isDefault"]),
        stations: Convert.strings(data["stations"]),
        raw: data
      )
    end
  end

  StockMove = Data.define(
    :id,
    :ingredient_id,
    :qty,
    :reason,
    :order_id,
    :invoice_id,
    :store_id,
    :note,
    :created_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        ingredient_id: Convert.str(data["ingredientId"]),
        qty: Convert.float(data["qty"]),
        reason: Convert.str(data["reason"]),
        order_id: Convert.str(data["orderId"]),
        invoice_id: Convert.str(data["invoiceId"]),
        store_id: Convert.str(data["storeId"]),
        note: Convert.str(data["note"]),
        created_at: Convert.time(data["createdAt"]),
        raw: data
      )
    end
  end

  ReviewRatings = Data.define(
    :food,
    :service,
    :atmosphere,
    :cleanliness,
    :price
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        food: Convert.float(data["food"]),
        service: Convert.float(data["service"]),
        atmosphere: Convert.float(data["atmosphere"]),
        cleanliness: Convert.float(data["cleanliness"]),
        price: Convert.float(data["price"]),
        raw: data
      )
    end
  end

  Review = Data.define(
    :id,
    :author,
    :overall,
    :ratings,
    :body,
    :visit_type,
    :visited_on,
    :verified,
    :reply,
    :replied_at,
    :created_at
  ) do
    include Model

    def self.from_hash(data)
      data = Convert.mapping(data)
      new(
        id: Convert.str(data["id"]),
        author: Convert.str(data["author"]),
        overall: Convert.float(data["overall"]),
        ratings: Convert.object(data["ratings"], ReviewRatings),
        body: Convert.str(data["body"]),
        visit_type: Convert.str(data["visitType"]),
        visited_on: Convert.time(data["visitedOn"]),
        verified: Convert.bool(data["verified"]),
        reply: Convert.str(data["reply"]),
        replied_at: Convert.time(data["repliedAt"]),
        created_at: Convert.time(data["createdAt"]),
        raw: data
      )
    end
  end
end
