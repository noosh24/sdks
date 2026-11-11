export type ReservationStatus = 'pending' | 'confirmed' | 'arriving' | 'checked_in' | 'completed' | 'cancelled' | 'no_show';
export type ReservationSource = 'noosh24' | 'open_api';
export type OrderKind = 'table' | 'counter' | 'delivery';
export type OrderStatus = 'pending_waiter' | 'new' | 'accepted' | 'preparing' | 'ready' | 'served' | 'cancelled';
export type OrderItemStatus = 'new' | 'preparing' | 'ready' | 'cancelled';
export type BillStatus = 'open' | 'bill_requested' | 'paid' | 'closed' | 'abandoned' | 'merged';
export type PaymentStatus = 'pending' | 'requires_action' | 'succeeded' | 'failed' | 'refunded';
export type PaymentMethod = 'card' | 'apple_pay' | 'google_pay' | 'azqr' | 'cash' | 'birbank' | 'platform';
export type PaymentTakenAt = 'till' | 'guest';
export type TableStatus = 'available' | 'reserved' | 'occupied' | 'cleaning' | 'payment';
export type LoyaltyProgramEarnBy = 'visit' | 'items';
export type LoyaltyProgramRewardScope = 'all' | 'categories' | 'items';
export type LoyaltyCardSource = 'panel' | 'till' | 'web' | 'app';
export type IngredientState = 'ok' | 'low' | 'empty';
export type SubscriptionStatus = 'none' | 'trial' | 'active' | 'expiring' | 'grace' | 'restricted' | 'suspended';

export interface Restaurant {
  id: string;
  name: string;
  slug: string;
}

export interface ApiKeyInfo {
  id: string;
  name: string;
  prefix: string;
  scopes: string[];
}

export interface Subscription {
  status: SubscriptionStatus;
  modules: string[];
}

export interface Features {
  loyalty: boolean;
  inventory: boolean;
}

export interface Whoami {
  restaurant: Restaurant;
  key: ApiKeyInfo;
  subscription: Subscription;
  features: Features;
}

export interface Category {
  name: string;
  position: number;
  products: number;
  available: number;
}

export interface Modifier {
  id: string;
  name: string;
  priceDelta: number;
  position: number;
}

export interface ModifierGroup {
  id: string;
  name: string;
  required: boolean;
  position: number;
  modifiers: Modifier[];
}

export interface ProductTranslation {
  name: string;
  description: string;
}

export interface Product {
  id: string;
  name: string;
  category: string;
  description: string;
  price: number;
  available: boolean;
  popular: boolean;
  position: number;
  prepMinutes: number;
  station: string;
  vatRate: number | null;
  vegetarian: boolean;
  spicy: boolean;
  allergens: string[];
  discountable: boolean;
  hasModifiers: boolean;
  image: string | null;
  video: string | null;
  modifierGroups?: ModifierGroup[];
  translations?: Record<string, ProductTranslation>;
}

export interface StopListItem {
  id: string;
  name: string;
  category: string;
  price: number;
}

export interface ReservationGuest {
  name: string;
  phone: string;
  email: string | null;
}

export interface ReservationTable {
  id: string;
  label: string;
}

export interface ReservationPreOrderItem {
  productId: string | null;
  name: string;
  price: number;
  qty: number;
  note: string | null;
}

export interface Reservation {
  id: string;
  code: string;
  status: ReservationStatus;
  source: ReservationSource;
  startsAt: string;
  endsAt: string;
  guests: number;
  zone: string;
  table: ReservationTable | null;
  guest: ReservationGuest;
  specialRequest: string | null;
  allergyNote: string | null;
  birthday: boolean;
  childChair: boolean;
  depositPaid: number;
  preOrder: ReservationPreOrderItem[];
  externalRef: string | null;
  decidedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AvailableTable {
  id: string;
  label: string;
  hallId: string;
  zone: string;
  seats: number;
  free: boolean;
}

export interface TableAvailability {
  startsAt: string;
  endsAt: string;
  durationMinutes: number;
  openTime: string;
  closeTime: string;
  tables: AvailableTable[];
}

export interface OrderItem {
  id: string;
  productId: string | null;
  name: string;
  qty: number;
  price: number;
  listPrice: number | null;
  modifiers: string | null;
  note: string | null;
  status: OrderItemStatus;
  comp: boolean;
  campaign: string | null;
  cancelReason: string | null;
}

export interface DeliveryPlatform {
  id: string | null;
  name: string | null;
  ref: string | null;
}

export interface OrderDelivery {
  status: string | null;
  platform: DeliveryPlatform | null;
  address: string | null;
  customerPhone: string | null;
  courierName: string | null;
  note: string | null;
  paymentMethod: string | null;
  fee: number | null;
  platformTotal: number | null;
  acceptedAt: string | null;
}

export interface Order {
  id: string;
  number: string;
  dailyNumber: number | null;
  kind: OrderKind;
  orderType: string | null;
  status: OrderStatus;
  tableId: string;
  billId: string;
  customerName: string | null;
  allergyNote: string | null;
  items: OrderItem[];
  subtotal: number;
  delivery: OrderDelivery | null;
  createdAt: string;
  updatedAt: string;
}

export interface Bill {
  id: string;
  tableId: string;
  status: BillStatus;
  guests: number;
  waiter: string | null;
  customerId: string | null;
  reservationId: string | null;
  orderIds: string[];
  subtotal: number;
  discountPercent: number;
  billDiscount: number;
  serviceFeePercent: number;
  serviceFee: number;
  total: number;
  paid: number;
  remaining: number;
  openedAt: string;
  closedAt: string | null;
}

export interface PaymentCard {
  maskedPan: string;
  scheme: string;
  bank: string;
}

export interface PaymentPlatform {
  id: string;
  name: string | null;
}

export interface Payment {
  id: string;
  status: PaymentStatus;
  method: PaymentMethod;
  recordedMethod: string;
  amount: number;
  tip: number;
  refundedAmount: number | null;
  refundedAt: string | null;
  refundReason: string | null;
  billId: string | null;
  reservationId: string | null;
  orderId: string | null;
  takenAt: PaymentTakenAt;
  card: PaymentCard | null;
  platform: PaymentPlatform | null;
  createdAt: string;
  settledAt: string | null;
}

export interface Hall {
  id: string;
  name: string;
  position: number;
}

export interface Table {
  id: string;
  label: string;
  hallId: string;
  zone: string;
  seats: number;
  shape: string;
  status: TableStatus;
  guests: number | null;
  waiter: string | null;
  seatedSince: string | null;
  openOrders: number;
  billId: string | null;
  billTotal: number | null;
  billRequested: boolean;
  billSettled: boolean;
  mergedInto: string | null;
}

export interface Customer {
  id: string;
  name: string;
  phone: string;
  note: string;
  createdAt: string;
  updatedAt: string;
}

export interface LoyaltyProgram {
  stampsNeeded: number;
  earnBy: LoyaltyProgramEarnBy;
  minBill: number;
  oncePerDay: boolean;
  rewardName: string;
  rewardScope: LoyaltyProgramRewardScope;
  rewardCategories: string[];
  rewardProductIds: string[];
  rewardMaxPrice: number;
  terms: string;
}

export interface LoyaltyCard {
  id: string;
  name: string;
  phone: string;
  stamps: number;
  totalStamps: number;
  redeemed: number;
  source: LoyaltyCardSource;
  lastVisitAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Ingredient {
  id: string;
  name: string;
  unit: string;
  stock: number;
  onOpenBills: number;
  available: number;
  state: IngredientState;
  lowStock: number;
  parStock: number;
  costPerUnit: number;
  value: number;
  prepared: boolean;
  byStore: Record<string, number>;
  updatedAt: string;
}

export interface StockStore {
  id: string;
  name: string;
  isDefault: boolean;
  stations: string[];
}

export interface StockMove {
  id: string;
  ingredientId: string;
  qty: number;
  reason: string;
  orderId: string | null;
  invoiceId: string | null;
  storeId: string | null;
  note: string | null;
  createdAt: string;
}

export interface ReviewRatings {
  food: number;
  service: number;
  atmosphere: number;
  cleanliness: number;
  price: number;
}

export interface Review {
  id: string;
  author: string;
  overall: number;
  ratings: ReviewRatings;
  body: string;
  visitType: string;
  visitedOn: string;
  verified: boolean;
  reply: string | null;
  repliedAt: string | null;
  createdAt: string;
}

export type ZReport = Record<string, unknown>;
