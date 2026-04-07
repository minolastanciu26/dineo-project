namespace DineoAPP.Models
{
    public class Restaurant
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string? Description { get; set; }
        public string? CuisineType { get; set; }
        public double Rating { get; set; }
    }
}