namespace DineoAPP.Models
{
    public class MonthlyOffer
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public Restaurant Restaurant { get; set; } = null!;
        public int Month { get; set; }
        public int Year { get; set; }
        public bool IsActive { get; set; } = true;
    }
}