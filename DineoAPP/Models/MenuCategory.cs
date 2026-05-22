namespace DineoAPP.Models
{
    public class MenuCategory
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public Restaurant Restaurant { get; set; } = null!;
        public string Name { get; set; } = string.Empty;
        public List<MenuItem>? MenuItems { get; set; }
    }
}