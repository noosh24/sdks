# frozen_string_literal: true

module Noosh24
  PreOrderLine = Data.define(:item_id, :qty, :note) do
    def self.coerce(line)
      return line if line.is_a?(PreOrderLine)
      raise ArgumentError, "A pre-order line is a PreOrderLine or a Hash" unless line.is_a?(Hash)

      fields = line.transform_keys(&:to_s)
      new(item_id: fields.fetch("item_id") { fields.fetch("itemId") }, qty: fields.fetch("qty"), note: fields["note"])
    end

    def initialize(item_id:, qty:, note: nil)
      super
    end

    def to_body
      body = { "itemId" => item_id, "qty" => qty }
      body["note"] = note unless note.nil?
      body
    end
  end

  NewReservation = Data.define(
    :date, :time, :guests, :guest_name, :phone, :email, :table_id, :zone, :special_request,
    :allergy_note, :birthday, :child_chair, :pre_order, :external_ref
  ) do
    def self.coerce(reservation)
      return reservation if reservation.is_a?(NewReservation)
      raise ArgumentError, "A reservation is a NewReservation or a Hash" unless reservation.is_a?(Hash)

      new(**reservation.transform_keys(&:to_sym))
    end

    def initialize(date:, time:, guests:, guest_name:, phone:, email: nil, table_id: nil, zone: nil,
                   special_request: nil, allergy_note: nil, birthday: nil, child_chair: nil, pre_order: nil,
                   external_ref: nil)
      lines = pre_order&.map { |line| PreOrderLine.coerce(line) }&.freeze
      super(date:, time:, guests:, guest_name:, phone:, email:, table_id:, zone:, special_request:,
            allergy_note:, birthday:, child_chair:, pre_order: lines, external_ref:)
    end

    def idempotent?
      !external_ref.to_s.strip.empty?
    end

    def to_body
      body = {
        "date" => Convert.date_param(date),
        "time" => time,
        "guests" => guests,
        "guestName" => guest_name,
        "phone" => phone
      }
      {
        "email" => email, "tableId" => table_id, "zone" => zone, "specialRequest" => special_request,
        "allergyNote" => allergy_note, "birthday" => birthday, "childChair" => child_chair
      }.each { |key, value| body[key] = value unless value.nil? }
      body["preOrder"] = pre_order.map(&:to_body) unless pre_order.nil?
      body["externalRef"] = external_ref unless external_ref.nil?
      body
    end
  end
end
