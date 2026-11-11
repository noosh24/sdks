package com.noosh24.openapi;

import com.noosh24.openapi.model.CreateReservationResult;
import com.noosh24.openapi.model.NewReservation;
import com.noosh24.openapi.model.PreOrderLine;
import com.noosh24.openapi.model.Reservation;
import com.noosh24.openapi.model.TableAvailability;
import java.time.LocalDate;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.ObjectNode;

public final class Reservations extends Resource {
    Reservations(Noosh24Client client) {
        super(client);
    }

    public Page<Reservation> list() {
        return list(ListParams.none());
    }

    public Page<Reservation> list(ListParams params) {
        return page("/reservations", Reservation::from, params.toQuery());
    }

    public PagedIterable<Reservation> iterate() {
        return iterate(ListParams.none());
    }

    public PagedIterable<Reservation> iterate(ListParams params) {
        return paginate("/reservations", Reservation::from, params.toQuery(), 100);
    }

    public Reservation get(String reservationId) {
        return one("/reservations/" + id(reservationId), Reservation::from, null);
    }

    public TableAvailability availability(String date, String time) {
        return availability(date, time, null);
    }

    public TableAvailability availability(String date, String time, @Nullable Integer guests) {
        Query query = new Query().add("date", date).add("time", time).add("guests", guests);
        return one("/reservations/availability", TableAvailability::from, query);
    }

    public TableAvailability availability(LocalDate date, String time) {
        return availability(date.toString(), time, null);
    }

    public TableAvailability availability(LocalDate date, String time, @Nullable Integer guests) {
        return availability(date.toString(), time, guests);
    }

    public CreateReservationResult create(NewReservation reservation) {
        ObjectNode body = JsonSupport.MAPPER.createObjectNode();
        body.put("date", reservation.date());
        body.put("time", reservation.time());
        body.put("guests", reservation.guests());
        body.put("guestName", reservation.guestName());
        body.put("phone", reservation.phone());
        putIfSet(body, "email", reservation.email());
        putIfSet(body, "tableId", reservation.tableId());
        putIfSet(body, "zone", reservation.zone());
        putIfSet(body, "specialRequest", reservation.specialRequest());
        putIfSet(body, "allergyNote", reservation.allergyNote());
        if (reservation.birthday() != null) {
            body.put("birthday", reservation.birthday());
        }
        if (reservation.childChair() != null) {
            body.put("childChair", reservation.childChair());
        }
        List<PreOrderLine> preOrder = reservation.preOrder();
        if (preOrder != null) {
            ArrayNode lines = body.putArray("preOrder");
            for (PreOrderLine line : preOrder) {
                ObjectNode item = lines.addObject();
                item.put("itemId", line.itemId());
                item.put("qty", line.qty());
                putIfSet(item, "note", line.note());
            }
        }
        putIfSet(body, "externalRef", reservation.externalRef());
        String ref = reservation.externalRef();
        boolean idempotent = ref != null && !ref.isBlank();
        Noosh24Client.Result result = client.request("POST", "/reservations", null, body, idempotent);
        return new CreateReservationResult(Reservation.from(result.data()), result.status() == 201);
    }

    public Reservation cancel(String reservationId) {
        return Reservation.from(client.request("POST", "/reservations/" + id(reservationId) + "/cancel", null, null, true).data());
    }

    private static void putIfSet(ObjectNode node, String key, @Nullable String value) {
        if (value != null) {
            node.put(key, value);
        }
    }
}
