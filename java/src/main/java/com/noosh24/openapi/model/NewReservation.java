package com.noosh24.openapi.model;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.jspecify.annotations.Nullable;

public record NewReservation(
        String date,
        String time,
        int guests,
        String guestName,
        String phone,
        @Nullable String email,
        @Nullable String tableId,
        @Nullable String zone,
        @Nullable String specialRequest,
        @Nullable String allergyNote,
        @Nullable Boolean birthday,
        @Nullable Boolean childChair,
        @Nullable List<PreOrderLine> preOrder,
        @Nullable String externalRef) {

    private static final DateTimeFormatter HOURS_MINUTES = DateTimeFormatter.ofPattern("HH:mm");

    public NewReservation {
        require(date, "date");
        require(time, "time");
        require(guestName, "guestName");
        require(phone, "phone");
        preOrder = preOrder == null ? null : Collections.unmodifiableList(new ArrayList<>(preOrder));
    }

    public static Builder builder() {
        return new Builder();
    }

    private static void require(@Nullable String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("A reservation needs " + name);
        }
    }

    public static final class Builder {
        private @Nullable String date;
        private @Nullable String time;
        private int guests;
        private @Nullable String guestName;
        private @Nullable String phone;
        private @Nullable String email;
        private @Nullable String tableId;
        private @Nullable String zone;
        private @Nullable String specialRequest;
        private @Nullable String allergyNote;
        private @Nullable Boolean birthday;
        private @Nullable Boolean childChair;
        private @Nullable List<PreOrderLine> preOrder;
        private @Nullable String externalRef;

        private Builder() {}

        public Builder date(String date) {
            this.date = date;
            return this;
        }

        public Builder date(LocalDate date) {
            this.date = date.toString();
            return this;
        }

        public Builder time(String time) {
            this.time = time;
            return this;
        }

        public Builder time(LocalTime time) {
            this.time = time.format(HOURS_MINUTES);
            return this;
        }

        public Builder guests(int guests) {
            this.guests = guests;
            return this;
        }

        public Builder guestName(String guestName) {
            this.guestName = guestName;
            return this;
        }

        public Builder phone(String phone) {
            this.phone = phone;
            return this;
        }

        public Builder email(@Nullable String email) {
            this.email = email;
            return this;
        }

        public Builder tableId(@Nullable String tableId) {
            this.tableId = tableId;
            return this;
        }

        public Builder zone(@Nullable String zone) {
            this.zone = zone;
            return this;
        }

        public Builder specialRequest(@Nullable String specialRequest) {
            this.specialRequest = specialRequest;
            return this;
        }

        public Builder allergyNote(@Nullable String allergyNote) {
            this.allergyNote = allergyNote;
            return this;
        }

        public Builder birthday(@Nullable Boolean birthday) {
            this.birthday = birthday;
            return this;
        }

        public Builder childChair(@Nullable Boolean childChair) {
            this.childChair = childChair;
            return this;
        }

        public Builder preOrder(@Nullable List<PreOrderLine> preOrder) {
            this.preOrder = preOrder == null ? null : new ArrayList<>(preOrder);
            return this;
        }

        public Builder addPreOrder(PreOrderLine line) {
            if (preOrder == null) {
                preOrder = new ArrayList<>();
            }
            preOrder.add(line);
            return this;
        }

        public Builder addPreOrder(String itemId, int qty) {
            return addPreOrder(new PreOrderLine(itemId, qty));
        }

        public Builder addPreOrder(String itemId, int qty, @Nullable String note) {
            return addPreOrder(new PreOrderLine(itemId, qty, note));
        }

        public Builder externalRef(@Nullable String externalRef) {
            this.externalRef = externalRef;
            return this;
        }

        public NewReservation build() {
            return new NewReservation(
                    date, time, guests, guestName, phone, email, tableId, zone, specialRequest, allergyNote, birthday,
                    childChair, preOrder, externalRef);
        }
    }
}
