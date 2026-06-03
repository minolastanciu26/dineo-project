// NOTE: Payment methods are stored locally in SharedPreferences on the device.
// This model is here only for reference / future server-side storage.
namespace DineoAPP.Models
{
    public class PaymentMethod
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public string CardholderName { get; set; } = string.Empty;
        public string MaskedNumber { get; set; } = string.Empty; // e.g. **** **** **** 4242
        public string CardType { get; set; } = "Visa";           // Visa / Mastercard
        public string ExpiryDate { get; set; } = string.Empty;  // MM/YY
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}