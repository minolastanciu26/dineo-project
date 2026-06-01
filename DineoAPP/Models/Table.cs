namespace DineoAPP.Models
{
    public class Table
    {
        public int Id { get; set; }
        public int RestaurantId { get; set; }
        public Restaurant? Restaurant { get; set; }
        public int TableNumber { get; set; }
        public int Seats { get; set; }
        public double PositionX { get; set; }
        public double PositionY { get; set; }
        public int Floor { get; set; } = 1;
    }
}