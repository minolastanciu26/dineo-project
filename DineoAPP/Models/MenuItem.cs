namespace DineoAPP.Models
{
    public class MenuItem
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public MenuCategory Category { get; set; } = null!;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsAvailable { get; set; } = true;
    }
}