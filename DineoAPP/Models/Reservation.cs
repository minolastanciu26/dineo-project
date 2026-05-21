namespace DineoAPP.Models
{
    public class Reservation
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int RestaurantId { get; set; }
        public Restaurant Restaurant { get; set; } = null!;
        public int TableId { get; set; }
        public Table Table { get; set; } = null!;
        public DateTime Date { get; set; }
        public TimeSpan Time { get; set; }
        public int GuestCount { get; set; }
        public string Status { get; set; } = "Pending";
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}