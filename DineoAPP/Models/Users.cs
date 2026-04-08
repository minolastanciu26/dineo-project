namespace DineoAPP.Models
{
    public class User
    {
        public int Id { get; set; } // Un număr unic pentru fiecare om
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}