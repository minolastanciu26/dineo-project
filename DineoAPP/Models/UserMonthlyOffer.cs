namespace DineoAPP.Models
{
    public class UserMonthlyOffer
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User User { get; set; } = null!;
        public int MonthlyOfferId { get; set; }
        public MonthlyOffer MonthlyOffer { get; set; } = null!;
        public bool IsUsed { get; set; } = false;
        public DateTime? UsedAt { get; set; }
    }
}