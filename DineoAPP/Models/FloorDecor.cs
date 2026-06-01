namespace DineoAPP.Models
{
    public class FloorDecor
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public Restaurant? Restaurant { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
        public double X { get; set; }
        public double Y { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
    }
}