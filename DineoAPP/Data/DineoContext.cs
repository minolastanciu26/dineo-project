using Microsoft.EntityFrameworkCore;
using DineoAPP.Models;

namespace DineoAPP.Data
{
    public class DineoContext : DbContext
    {
        public DineoContext(DbContextOptions<DineoContext> options) : base(options) { }

        public DbSet<Restaurant> Restaurants { get; set; }
        public DbSet<User> Users { get; set; }
    }
}