import 'convert.dart';

typedef ZReport = Map<String, dynamic>;

class Restaurant {
  const Restaurant({this.id, this.name, this.slug, this.raw = const {}});

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
    id: readString(json['id']),
    name: readString(json['name']),
    slug: readString(json['slug']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? slug;
  final Map<String, dynamic> raw;
}

class ApiKeyInfo {
  const ApiKeyInfo({
    this.id,
    this.name,
    this.prefix,
    this.scopes = const [],
    this.raw = const {},
  });

  factory ApiKeyInfo.fromJson(Map<String, dynamic> json) => ApiKeyInfo(
    id: readString(json['id']),
    name: readString(json['name']),
    prefix: readString(json['prefix']),
    scopes: readStrings(json['scopes']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? prefix;
  final List<String> scopes;
  final Map<String, dynamic> raw;
}

class Subscription {
  const Subscription({
    this.status,
    this.modules = const [],
    this.raw = const {},
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    status: readString(json['status']),
    modules: readStrings(json['modules']),
    raw: Map.unmodifiable(json),
  );

  final String? status;
  final List<String> modules;
  final Map<String, dynamic> raw;
}

class Features {
  const Features({this.loyalty, this.inventory, this.raw = const {}});

  factory Features.fromJson(Map<String, dynamic> json) => Features(
    loyalty: readBool(json['loyalty']),
    inventory: readBool(json['inventory']),
    raw: Map.unmodifiable(json),
  );

  final bool? loyalty;
  final bool? inventory;
  final Map<String, dynamic> raw;
}

class Whoami {
  const Whoami({
    this.restaurant,
    this.key,
    this.subscription,
    this.features,
    this.raw = const {},
  });

  factory Whoami.fromJson(Map<String, dynamic> json) => Whoami(
    restaurant: readObject(json['restaurant'], Restaurant.fromJson),
    key: readObject(json['key'], ApiKeyInfo.fromJson),
    subscription: readObject(json['subscription'], Subscription.fromJson),
    features: readObject(json['features'], Features.fromJson),
    raw: Map.unmodifiable(json),
  );

  final Restaurant? restaurant;
  final ApiKeyInfo? key;
  final Subscription? subscription;
  final Features? features;
  final Map<String, dynamic> raw;
}

class Category {
  const Category({
    this.name,
    this.position,
    this.products,
    this.available,
    this.raw = const {},
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: readString(json['name']),
    position: readInt(json['position']),
    products: readInt(json['products']),
    available: readInt(json['available']),
    raw: Map.unmodifiable(json),
  );

  final String? name;
  final int? position;
  final int? products;
  final int? available;
  final Map<String, dynamic> raw;
}

class Modifier {
  const Modifier({
    this.id,
    this.name,
    this.priceDelta,
    this.position,
    this.raw = const {},
  });

  factory Modifier.fromJson(Map<String, dynamic> json) => Modifier(
    id: readString(json['id']),
    name: readString(json['name']),
    priceDelta: readDouble(json['priceDelta']),
    position: readInt(json['position']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final double? priceDelta;
  final int? position;
  final Map<String, dynamic> raw;
}

class ModifierGroup {
  const ModifierGroup({
    this.id,
    this.name,
    this.required,
    this.position,
    this.modifiers = const [],
    this.raw = const {},
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
    id: readString(json['id']),
    name: readString(json['name']),
    required: readBool(json['required']),
    position: readInt(json['position']),
    modifiers: readList(json['modifiers'], Modifier.fromJson),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final bool? required;
  final int? position;
  final List<Modifier> modifiers;
  final Map<String, dynamic> raw;
}

class ProductTranslation {
  const ProductTranslation({this.name, this.description, this.raw = const {}});

  factory ProductTranslation.fromJson(Map<String, dynamic> json) =>
      ProductTranslation(
        name: readString(json['name']),
        description: readString(json['description']),
        raw: Map.unmodifiable(json),
      );

  final String? name;
  final String? description;
  final Map<String, dynamic> raw;
}

class Product {
  const Product({
    this.id,
    this.name,
    this.category,
    this.description,
    this.price,
    this.available,
    this.popular,
    this.position,
    this.prepMinutes,
    this.station,
    this.vatRate,
    this.vegetarian,
    this.spicy,
    this.allergens = const [],
    this.discountable,
    this.hasModifiers,
    this.image,
    this.video,
    this.modifierGroups = const [],
    this.translations = const {},
    this.raw = const {},
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: readString(json['id']),
    name: readString(json['name']),
    category: readString(json['category']),
    description: readString(json['description']),
    price: readDouble(json['price']),
    available: readBool(json['available']),
    popular: readBool(json['popular']),
    position: readInt(json['position']),
    prepMinutes: readInt(json['prepMinutes']),
    station: readString(json['station']),
    vatRate: readDouble(json['vatRate']),
    vegetarian: readBool(json['vegetarian']),
    spicy: readBool(json['spicy']),
    allergens: readStrings(json['allergens']),
    discountable: readBool(json['discountable']),
    hasModifiers: readBool(json['hasModifiers']),
    image: readString(json['image']),
    video: readString(json['video']),
    modifierGroups: readList(json['modifierGroups'], ModifierGroup.fromJson),
    translations: readMap(json['translations'], ProductTranslation.fromJson),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? category;
  final String? description;
  final double? price;
  final bool? available;
  final bool? popular;
  final int? position;
  final int? prepMinutes;
  final String? station;
  final double? vatRate;
  final bool? vegetarian;
  final bool? spicy;
  final List<String> allergens;
  final bool? discountable;
  final bool? hasModifiers;
  final String? image;
  final String? video;
  final List<ModifierGroup> modifierGroups;
  final Map<String, ProductTranslation> translations;
  final Map<String, dynamic> raw;
}

class StopListItem {
  const StopListItem({
    this.id,
    this.name,
    this.category,
    this.price,
    this.raw = const {},
  });

  factory StopListItem.fromJson(Map<String, dynamic> json) => StopListItem(
    id: readString(json['id']),
    name: readString(json['name']),
    category: readString(json['category']),
    price: readDouble(json['price']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? category;
  final double? price;
  final Map<String, dynamic> raw;
}

class ReservationGuest {
  const ReservationGuest({
    this.name,
    this.phone,
    this.email,
    this.raw = const {},
  });

  factory ReservationGuest.fromJson(Map<String, dynamic> json) =>
      ReservationGuest(
        name: readString(json['name']),
        phone: readString(json['phone']),
        email: readString(json['email']),
        raw: Map.unmodifiable(json),
      );

  final String? name;
  final String? phone;
  final String? email;
  final Map<String, dynamic> raw;
}

class ReservationTable {
  const ReservationTable({this.id, this.label, this.raw = const {}});

  factory ReservationTable.fromJson(Map<String, dynamic> json) =>
      ReservationTable(
        id: readString(json['id']),
        label: readString(json['label']),
        raw: Map.unmodifiable(json),
      );

  final String? id;
  final String? label;
  final Map<String, dynamic> raw;
}

class ReservationPreOrderItem {
  const ReservationPreOrderItem({
    this.productId,
    this.name,
    this.price,
    this.qty,
    this.note,
    this.raw = const {},
  });

  factory ReservationPreOrderItem.fromJson(Map<String, dynamic> json) =>
      ReservationPreOrderItem(
        productId: readString(json['productId']),
        name: readString(json['name']),
        price: readDouble(json['price']),
        qty: readInt(json['qty']),
        note: readString(json['note']),
        raw: Map.unmodifiable(json),
      );

  final String? productId;
  final String? name;
  final double? price;
  final int? qty;
  final String? note;
  final Map<String, dynamic> raw;
}

class Reservation {
  const Reservation({
    this.id,
    this.code,
    this.status,
    this.source,
    this.startsAt,
    this.endsAt,
    this.guests,
    this.zone,
    this.table,
    this.guest,
    this.specialRequest,
    this.allergyNote,
    this.birthday,
    this.childChair,
    this.depositPaid,
    this.preOrder = const [],
    this.externalRef,
    this.decidedAt,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
    id: readString(json['id']),
    code: readString(json['code']),
    status: readString(json['status']),
    source: readString(json['source']),
    startsAt: readDateTime(json['startsAt']),
    endsAt: readDateTime(json['endsAt']),
    guests: readInt(json['guests']),
    zone: readString(json['zone']),
    table: readObject(json['table'], ReservationTable.fromJson),
    guest: readObject(json['guest'], ReservationGuest.fromJson),
    specialRequest: readString(json['specialRequest']),
    allergyNote: readString(json['allergyNote']),
    birthday: readBool(json['birthday']),
    childChair: readBool(json['childChair']),
    depositPaid: readDouble(json['depositPaid']),
    preOrder: readList(json['preOrder'], ReservationPreOrderItem.fromJson),
    externalRef: readString(json['externalRef']),
    decidedAt: readDateTime(json['decidedAt']),
    createdAt: readDateTime(json['createdAt']),
    updatedAt: readDateTime(json['updatedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? code;
  final String? status;
  final String? source;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? guests;
  final String? zone;
  final ReservationTable? table;
  final ReservationGuest? guest;
  final String? specialRequest;
  final String? allergyNote;
  final bool? birthday;
  final bool? childChair;
  final double? depositPaid;
  final List<ReservationPreOrderItem> preOrder;
  final String? externalRef;
  final DateTime? decidedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
}

class AvailableTable {
  const AvailableTable({
    this.id,
    this.label,
    this.hallId,
    this.zone,
    this.seats,
    this.free,
    this.raw = const {},
  });

  factory AvailableTable.fromJson(Map<String, dynamic> json) => AvailableTable(
    id: readString(json['id']),
    label: readString(json['label']),
    hallId: readString(json['hallId']),
    zone: readString(json['zone']),
    seats: readInt(json['seats']),
    free: readBool(json['free']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? label;
  final String? hallId;
  final String? zone;
  final int? seats;
  final bool? free;
  final Map<String, dynamic> raw;
}

class TableAvailability {
  const TableAvailability({
    this.startsAt,
    this.endsAt,
    this.durationMinutes,
    this.openTime,
    this.closeTime,
    this.tables = const [],
    this.raw = const {},
  });

  factory TableAvailability.fromJson(Map<String, dynamic> json) =>
      TableAvailability(
        startsAt: readDateTime(json['startsAt']),
        endsAt: readDateTime(json['endsAt']),
        durationMinutes: readInt(json['durationMinutes']),
        openTime: readString(json['openTime']),
        closeTime: readString(json['closeTime']),
        tables: readList(json['tables'], AvailableTable.fromJson),
        raw: Map.unmodifiable(json),
      );

  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? durationMinutes;
  final String? openTime;
  final String? closeTime;
  final List<AvailableTable> tables;
  final Map<String, dynamic> raw;
}

class OrderItem {
  const OrderItem({
    this.id,
    this.productId,
    this.name,
    this.qty,
    this.price,
    this.listPrice,
    this.modifiers,
    this.note,
    this.status,
    this.comp,
    this.campaign,
    this.cancelReason,
    this.raw = const {},
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: readString(json['id']),
    productId: readString(json['productId']),
    name: readString(json['name']),
    qty: readInt(json['qty']),
    price: readDouble(json['price']),
    listPrice: readDouble(json['listPrice']),
    modifiers: readString(json['modifiers']),
    note: readString(json['note']),
    status: readString(json['status']),
    comp: readBool(json['comp']),
    campaign: readString(json['campaign']),
    cancelReason: readString(json['cancelReason']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? productId;
  final String? name;
  final int? qty;
  final double? price;
  final double? listPrice;
  final String? modifiers;
  final String? note;
  final String? status;
  final bool? comp;
  final String? campaign;
  final String? cancelReason;
  final Map<String, dynamic> raw;
}

class DeliveryPlatform {
  const DeliveryPlatform({this.id, this.name, this.ref, this.raw = const {}});

  factory DeliveryPlatform.fromJson(Map<String, dynamic> json) =>
      DeliveryPlatform(
        id: readString(json['id']),
        name: readString(json['name']),
        ref: readString(json['ref']),
        raw: Map.unmodifiable(json),
      );

  final String? id;
  final String? name;
  final String? ref;
  final Map<String, dynamic> raw;
}

class OrderDelivery {
  const OrderDelivery({
    this.status,
    this.platform,
    this.address,
    this.customerPhone,
    this.courierName,
    this.note,
    this.paymentMethod,
    this.fee,
    this.platformTotal,
    this.acceptedAt,
    this.raw = const {},
  });

  factory OrderDelivery.fromJson(Map<String, dynamic> json) => OrderDelivery(
    status: readString(json['status']),
    platform: readObject(json['platform'], DeliveryPlatform.fromJson),
    address: readString(json['address']),
    customerPhone: readString(json['customerPhone']),
    courierName: readString(json['courierName']),
    note: readString(json['note']),
    paymentMethod: readString(json['paymentMethod']),
    fee: readDouble(json['fee']),
    platformTotal: readDouble(json['platformTotal']),
    acceptedAt: readDateTime(json['acceptedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? status;
  final DeliveryPlatform? platform;
  final String? address;
  final String? customerPhone;
  final String? courierName;
  final String? note;
  final String? paymentMethod;
  final double? fee;
  final double? platformTotal;
  final DateTime? acceptedAt;
  final Map<String, dynamic> raw;
}

class Order {
  const Order({
    this.id,
    this.number,
    this.dailyNumber,
    this.kind,
    this.orderType,
    this.status,
    this.tableId,
    this.billId,
    this.customerName,
    this.allergyNote,
    this.items = const [],
    this.subtotal,
    this.delivery,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: readString(json['id']),
    number: readString(json['number']),
    dailyNumber: readInt(json['dailyNumber']),
    kind: readString(json['kind']),
    orderType: readString(json['orderType']),
    status: readString(json['status']),
    tableId: readString(json['tableId']),
    billId: readString(json['billId']),
    customerName: readString(json['customerName']),
    allergyNote: readString(json['allergyNote']),
    items: readList(json['items'], OrderItem.fromJson),
    subtotal: readDouble(json['subtotal']),
    delivery: readObject(json['delivery'], OrderDelivery.fromJson),
    createdAt: readDateTime(json['createdAt']),
    updatedAt: readDateTime(json['updatedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? number;
  final int? dailyNumber;
  final String? kind;
  final String? orderType;
  final String? status;
  final String? tableId;
  final String? billId;
  final String? customerName;
  final String? allergyNote;
  final List<OrderItem> items;
  final double? subtotal;
  final OrderDelivery? delivery;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
}

class Bill {
  const Bill({
    this.id,
    this.tableId,
    this.status,
    this.guests,
    this.waiter,
    this.customerId,
    this.reservationId,
    this.orderIds = const [],
    this.subtotal,
    this.discountPercent,
    this.billDiscount,
    this.serviceFeePercent,
    this.serviceFee,
    this.total,
    this.paid,
    this.remaining,
    this.openedAt,
    this.closedAt,
    this.raw = const {},
  });

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: readString(json['id']),
    tableId: readString(json['tableId']),
    status: readString(json['status']),
    guests: readInt(json['guests']),
    waiter: readString(json['waiter']),
    customerId: readString(json['customerId']),
    reservationId: readString(json['reservationId']),
    orderIds: readStrings(json['orderIds']),
    subtotal: readDouble(json['subtotal']),
    discountPercent: readDouble(json['discountPercent']),
    billDiscount: readDouble(json['billDiscount']),
    serviceFeePercent: readDouble(json['serviceFeePercent']),
    serviceFee: readDouble(json['serviceFee']),
    total: readDouble(json['total']),
    paid: readDouble(json['paid']),
    remaining: readDouble(json['remaining']),
    openedAt: readDateTime(json['openedAt']),
    closedAt: readDateTime(json['closedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? tableId;
  final String? status;
  final int? guests;
  final String? waiter;
  final String? customerId;
  final String? reservationId;
  final List<String> orderIds;
  final double? subtotal;
  final double? discountPercent;
  final double? billDiscount;
  final double? serviceFeePercent;
  final double? serviceFee;
  final double? total;
  final double? paid;
  final double? remaining;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final Map<String, dynamic> raw;
}

class PaymentCard {
  const PaymentCard({
    this.maskedPan,
    this.scheme,
    this.bank,
    this.raw = const {},
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) => PaymentCard(
    maskedPan: readString(json['maskedPan']),
    scheme: readString(json['scheme']),
    bank: readString(json['bank']),
    raw: Map.unmodifiable(json),
  );

  final String? maskedPan;
  final String? scheme;
  final String? bank;
  final Map<String, dynamic> raw;
}

class PaymentPlatform {
  const PaymentPlatform({this.id, this.name, this.raw = const {}});

  factory PaymentPlatform.fromJson(Map<String, dynamic> json) =>
      PaymentPlatform(
        id: readString(json['id']),
        name: readString(json['name']),
        raw: Map.unmodifiable(json),
      );

  final String? id;
  final String? name;
  final Map<String, dynamic> raw;
}

class Payment {
  const Payment({
    this.id,
    this.status,
    this.method,
    this.recordedMethod,
    this.amount,
    this.tip,
    this.refundedAmount,
    this.refundedAt,
    this.refundReason,
    this.billId,
    this.reservationId,
    this.orderId,
    this.takenAt,
    this.card,
    this.platform,
    this.createdAt,
    this.settledAt,
    this.raw = const {},
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: readString(json['id']),
    status: readString(json['status']),
    method: readString(json['method']),
    recordedMethod: readString(json['recordedMethod']),
    amount: readDouble(json['amount']),
    tip: readDouble(json['tip']),
    refundedAmount: readDouble(json['refundedAmount']),
    refundedAt: readDateTime(json['refundedAt']),
    refundReason: readString(json['refundReason']),
    billId: readString(json['billId']),
    reservationId: readString(json['reservationId']),
    orderId: readString(json['orderId']),
    takenAt: readString(json['takenAt']),
    card: readObject(json['card'], PaymentCard.fromJson),
    platform: readObject(json['platform'], PaymentPlatform.fromJson),
    createdAt: readDateTime(json['createdAt']),
    settledAt: readDateTime(json['settledAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? status;
  final String? method;
  final String? recordedMethod;
  final double? amount;
  final double? tip;
  final double? refundedAmount;
  final DateTime? refundedAt;
  final String? refundReason;
  final String? billId;
  final String? reservationId;
  final String? orderId;
  final String? takenAt;
  final PaymentCard? card;
  final PaymentPlatform? platform;
  final DateTime? createdAt;
  final DateTime? settledAt;
  final Map<String, dynamic> raw;
}

class Hall {
  const Hall({this.id, this.name, this.position, this.raw = const {}});

  factory Hall.fromJson(Map<String, dynamic> json) => Hall(
    id: readString(json['id']),
    name: readString(json['name']),
    position: readInt(json['position']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final int? position;
  final Map<String, dynamic> raw;
}

class Table {
  const Table({
    this.id,
    this.label,
    this.hallId,
    this.zone,
    this.seats,
    this.shape,
    this.status,
    this.guests,
    this.waiter,
    this.seatedSince,
    this.openOrders,
    this.billId,
    this.billTotal,
    this.billRequested,
    this.billSettled,
    this.mergedInto,
    this.raw = const {},
  });

  factory Table.fromJson(Map<String, dynamic> json) => Table(
    id: readString(json['id']),
    label: readString(json['label']),
    hallId: readString(json['hallId']),
    zone: readString(json['zone']),
    seats: readInt(json['seats']),
    shape: readString(json['shape']),
    status: readString(json['status']),
    guests: readInt(json['guests']),
    waiter: readString(json['waiter']),
    seatedSince: readString(json['seatedSince']),
    openOrders: readInt(json['openOrders']),
    billId: readString(json['billId']),
    billTotal: readDouble(json['billTotal']),
    billRequested: readBool(json['billRequested']),
    billSettled: readBool(json['billSettled']),
    mergedInto: readString(json['mergedInto']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? label;
  final String? hallId;
  final String? zone;
  final int? seats;
  final String? shape;
  final String? status;
  final int? guests;
  final String? waiter;
  final String? seatedSince;
  final int? openOrders;
  final String? billId;
  final double? billTotal;
  final bool? billRequested;
  final bool? billSettled;
  final String? mergedInto;
  final Map<String, dynamic> raw;
}

class Customer {
  const Customer({
    this.id,
    this.name,
    this.phone,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: readString(json['id']),
    name: readString(json['name']),
    phone: readString(json['phone']),
    note: readString(json['note']),
    createdAt: readDateTime(json['createdAt']),
    updatedAt: readDateTime(json['updatedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? phone;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
}

class LoyaltyProgram {
  const LoyaltyProgram({
    this.stampsNeeded,
    this.earnBy,
    this.minBill,
    this.oncePerDay,
    this.rewardName,
    this.rewardScope,
    this.rewardCategories = const [],
    this.rewardProductIds = const [],
    this.rewardMaxPrice,
    this.terms,
    this.raw = const {},
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) => LoyaltyProgram(
    stampsNeeded: readInt(json['stampsNeeded']),
    earnBy: readString(json['earnBy']),
    minBill: readDouble(json['minBill']),
    oncePerDay: readBool(json['oncePerDay']),
    rewardName: readString(json['rewardName']),
    rewardScope: readString(json['rewardScope']),
    rewardCategories: readStrings(json['rewardCategories']),
    rewardProductIds: readStrings(json['rewardProductIds']),
    rewardMaxPrice: readDouble(json['rewardMaxPrice']),
    terms: readString(json['terms']),
    raw: Map.unmodifiable(json),
  );

  final int? stampsNeeded;
  final String? earnBy;
  final double? minBill;
  final bool? oncePerDay;
  final String? rewardName;
  final String? rewardScope;
  final List<String> rewardCategories;
  final List<String> rewardProductIds;
  final double? rewardMaxPrice;
  final String? terms;
  final Map<String, dynamic> raw;
}

class LoyaltyCard {
  const LoyaltyCard({
    this.id,
    this.name,
    this.phone,
    this.stamps,
    this.totalStamps,
    this.redeemed,
    this.source,
    this.lastVisitAt,
    this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
    id: readString(json['id']),
    name: readString(json['name']),
    phone: readString(json['phone']),
    stamps: readInt(json['stamps']),
    totalStamps: readInt(json['totalStamps']),
    redeemed: readInt(json['redeemed']),
    source: readString(json['source']),
    lastVisitAt: readDateTime(json['lastVisitAt']),
    createdAt: readDateTime(json['createdAt']),
    updatedAt: readDateTime(json['updatedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? phone;
  final int? stamps;
  final int? totalStamps;
  final int? redeemed;
  final String? source;
  final DateTime? lastVisitAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
}

class Ingredient {
  const Ingredient({
    this.id,
    this.name,
    this.unit,
    this.stock,
    this.onOpenBills,
    this.available,
    this.state,
    this.lowStock,
    this.parStock,
    this.costPerUnit,
    this.value,
    this.prepared,
    this.byStore = const {},
    this.updatedAt,
    this.raw = const {},
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: readString(json['id']),
    name: readString(json['name']),
    unit: readString(json['unit']),
    stock: readDouble(json['stock']),
    onOpenBills: readDouble(json['onOpenBills']),
    available: readDouble(json['available']),
    state: readString(json['state']),
    lowStock: readDouble(json['lowStock']),
    parStock: readDouble(json['parStock']),
    costPerUnit: readDouble(json['costPerUnit']),
    value: readDouble(json['value']),
    prepared: readBool(json['prepared']),
    byStore: readDoubles(json['byStore']),
    updatedAt: readDateTime(json['updatedAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final String? unit;
  final double? stock;
  final double? onOpenBills;
  final double? available;
  final String? state;
  final double? lowStock;
  final double? parStock;
  final double? costPerUnit;
  final double? value;
  final bool? prepared;
  final Map<String, double> byStore;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
}

class StockStore {
  const StockStore({
    this.id,
    this.name,
    this.isDefault,
    this.stations = const [],
    this.raw = const {},
  });

  factory StockStore.fromJson(Map<String, dynamic> json) => StockStore(
    id: readString(json['id']),
    name: readString(json['name']),
    isDefault: readBool(json['isDefault']),
    stations: readStrings(json['stations']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? name;
  final bool? isDefault;
  final List<String> stations;
  final Map<String, dynamic> raw;
}

class StockMove {
  const StockMove({
    this.id,
    this.ingredientId,
    this.qty,
    this.reason,
    this.orderId,
    this.invoiceId,
    this.storeId,
    this.note,
    this.createdAt,
    this.raw = const {},
  });

  factory StockMove.fromJson(Map<String, dynamic> json) => StockMove(
    id: readString(json['id']),
    ingredientId: readString(json['ingredientId']),
    qty: readDouble(json['qty']),
    reason: readString(json['reason']),
    orderId: readString(json['orderId']),
    invoiceId: readString(json['invoiceId']),
    storeId: readString(json['storeId']),
    note: readString(json['note']),
    createdAt: readDateTime(json['createdAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? ingredientId;
  final double? qty;
  final String? reason;
  final String? orderId;
  final String? invoiceId;
  final String? storeId;
  final String? note;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;
}

class ReviewRatings {
  const ReviewRatings({
    this.food,
    this.service,
    this.atmosphere,
    this.cleanliness,
    this.price,
    this.raw = const {},
  });

  factory ReviewRatings.fromJson(Map<String, dynamic> json) => ReviewRatings(
    food: readDouble(json['food']),
    service: readDouble(json['service']),
    atmosphere: readDouble(json['atmosphere']),
    cleanliness: readDouble(json['cleanliness']),
    price: readDouble(json['price']),
    raw: Map.unmodifiable(json),
  );

  final double? food;
  final double? service;
  final double? atmosphere;
  final double? cleanliness;
  final double? price;
  final Map<String, dynamic> raw;
}

class Review {
  const Review({
    this.id,
    this.author,
    this.overall,
    this.ratings,
    this.body,
    this.visitType,
    this.visitedOn,
    this.verified,
    this.reply,
    this.repliedAt,
    this.createdAt,
    this.raw = const {},
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: readString(json['id']),
    author: readString(json['author']),
    overall: readDouble(json['overall']),
    ratings: readObject(json['ratings'], ReviewRatings.fromJson),
    body: readString(json['body']),
    visitType: readString(json['visitType']),
    visitedOn: readDateTime(json['visitedOn']),
    verified: readBool(json['verified']),
    reply: readString(json['reply']),
    repliedAt: readDateTime(json['repliedAt']),
    createdAt: readDateTime(json['createdAt']),
    raw: Map.unmodifiable(json),
  );

  final String? id;
  final String? author;
  final double? overall;
  final ReviewRatings? ratings;
  final String? body;
  final String? visitType;
  final DateTime? visitedOn;
  final bool? verified;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;
}
