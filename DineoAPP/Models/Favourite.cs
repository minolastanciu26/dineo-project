namespace DineoAPP.Models
{
    public class Favourite
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int RestaurantId { get; set; }
        public Restaurant Restaurant { get; set; } = null!;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}