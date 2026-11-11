import type { Noosh24 } from '../client.js';
import type { Reservation, TableAvailability } from '../models.js';
import { fetchPage, paginate, pathId, type ListParams, type Page } from '../pagination.js';

export interface NewReservationPreOrderLine {
  itemId: string;
  qty: number;
  note?: string;
}

export interface NewReservation {
  date: string;
  time: string;
  guests: number;
  guestName: string;
  phone: string;
  email?: string;
  tableId?: string;
  zone?: string;
  specialRequest?: string;
  allergyNote?: string;
  birthday?: boolean;
  childChair?: boolean;
  preOrder?: NewReservationPreOrderLine[];
  externalRef?: string;
}

export interface CreateReservationResult {
  reservation: Reservation;
  created: boolean;
}

export class Reservations {
  constructor(private readonly client: Noosh24) {}

  list(params: ListParams = {}): Promise<Page<Reservation>> {
    return fetchPage<Reservation>(this.client, '/reservations', params);
  }

  iterate(params: ListParams = {}): AsyncGenerator<Reservation, void, undefined> {
    return paginate<Reservation>(this.client, '/reservations', params, 100);
  }

  async get(reservationId: string): Promise<Reservation> {
    return (await this.client.request<Reservation>('GET', `/reservations/${pathId(reservationId)}`)).data;
  }

  async availability(date: string, time: string, guests?: number): Promise<TableAvailability> {
    const { data } = await this.client.request<TableAvailability>('GET', '/reservations/availability', {
      query: { date, time, guests },
    });
    return data;
  }

  async create(reservation: NewReservation): Promise<CreateReservationResult> {
    const idempotent = typeof reservation.externalRef === 'string' && reservation.externalRef.trim() !== '';
    const { status, data } = await this.client.request<Reservation>('POST', '/reservations', {
      body: reservation,
      retryable: idempotent,
    });
    return { reservation: data, created: status === 201 };
  }

  async cancel(reservationId: string): Promise<Reservation> {
    return (await this.client.request<Reservation>('POST', `/reservations/${pathId(reservationId)}/cancel`)).data;
  }
}
