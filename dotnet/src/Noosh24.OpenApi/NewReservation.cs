using System.Text.Json.Serialization;

namespace Noosh24.OpenApi;

public sealed record NewReservation
{
    [JsonPropertyName("date")]
    public required DateOnly Date { get; init; }

    [JsonPropertyName("time")]
    public required TimeOnly Time { get; init; }

    [JsonPropertyName("guests")]
    public required int Guests { get; init; }

    [JsonPropertyName("guestName")]
    public required string GuestName { get; init; }

    [JsonPropertyName("phone")]
    public required string Phone { get; init; }

    [JsonPropertyName("email")]
    public string? Email { get; init; }

    [JsonPropertyName("tableId")]
    public string? TableId { get; init; }

    [JsonPropertyName("zone")]
    public string? Zone { get; init; }

    [JsonPropertyName("specialRequest")]
    public string? SpecialRequest { get; init; }

    [JsonPropertyName("allergyNote")]
    public string? AllergyNote { get; init; }

    [JsonPropertyName("birthday")]
    public bool? Birthday { get; init; }

    [JsonPropertyName("childChair")]
    public bool? ChildChair { get; init; }

    [JsonPropertyName("preOrder")]
    public IReadOnlyList<PreOrderLine>? PreOrder { get; init; }

    [JsonPropertyName("externalRef")]
    public string? ExternalRef { get; init; }
}

public sealed record PreOrderLine
{
    public PreOrderLine()
    {
    }

    [System.Diagnostics.CodeAnalysis.SetsRequiredMembers]
    public PreOrderLine(string itemId, int qty, string? note = null)
    {
        ItemId = itemId;
        Qty = qty;
        Note = note;
    }

    [JsonPropertyName("itemId")]
    public required string ItemId { get; init; }

    [JsonPropertyName("qty")]
    public required int Qty { get; init; }

    [JsonPropertyName("note")]
    public string? Note { get; init; }
}

public sealed record CreateReservationResult(Reservation Reservation, bool Created);
