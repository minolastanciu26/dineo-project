using Microsoft.EntityFrameworkCore;
using DineoAPP.Models;

namespace DineoAPP.Data
{
    public class DineoContext : DbContext
    {
        public DineoContext(DbContextOptions<DineoContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Restaurant> Restaurants { get; set; }
        public DbSet<Table> Tables { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<MenuCategory> MenuCategories { get; set; }
        public DbSet<MenuItem> MenuItems { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<Favourite> Favourites { get; set; }
        public DbSet<FavouriteItem> FavouriteItems { get; set; }
        public DbSet<MonthlyOffer> MonthlyOffers { get; set; }
        public DbSet<UserMonthlyOffer> UserMonthlyOffers { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<DiscoveredRestaurant> DiscoveredRestaurants { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // User
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            // Restaurant
            modelBuilder.Entity<Restaurant>()
                .Property(r => r.Rating)
                .HasDefaultValue(0.0);

            // Table
            modelBuilder.Entity<Table>()
                .HasOne(t => t.Restaurant)
                .WithMany()
                .HasForeignKey(t => t.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);

            // Reservation
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Restaurant)
                .WithMany()
                .HasForeignKey(r => r.RestaurantId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Table)
                .WithMany()
                .HasForeignKey(r => r.TableId)
                .OnDelete(DeleteBehavior.NoAction);

            // MenuCategory
            modelBuilder.Entity<MenuCategory>()
                .HasOne(mc => mc.Restaurant)
                .WithMany()
                .HasForeignKey(mc => mc.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);

            // MenuItem
            modelBuilder.Entity<MenuItem>()
                .HasOne(mi => mi.Category)
                .WithMany()
                .HasForeignKey(mi => mi.CategoryId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<MenuItem>()
                .Property(mi => mi.Price)
                .HasColumnType("decimal(10,2)");

            // Order
            modelBuilder.Entity<Order>()
                .HasOne(o => o.User)
                .WithMany()
                .HasForeignKey(o => o.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Restaurant)
                .WithMany()
                .HasForeignKey(o => o.RestaurantId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Order>()
                .Property(o => o.TotalPrice)
                .HasColumnType("decimal(10,2)");

            // OrderItem
            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.Order)
                .WithMany()
                .HasForeignKey(oi => oi.OrderId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<OrderItem>()
                .HasOne(oi => oi.MenuItem)
                .WithMany()
                .HasForeignKey(oi => oi.MenuItemId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<OrderItem>()
                .Property(oi => oi.Price)
                .HasColumnType("decimal(10,2)");

            // Review
            modelBuilder.Entity<Review>()
                .HasOne(r => r.User)
                .WithMany()
                .HasForeignKey(r => r.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Review>()
                .HasOne(r => r.Restaurant)
                .WithMany()
                .HasForeignKey(r => r.RestaurantId)
                .OnDelete(DeleteBehavior.NoAction);

            // Favourite
            modelBuilder.Entity<Favourite>()
                .HasOne(f => f.User)
                .WithMany()
                .HasForeignKey(f => f.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Favourite>()
                .HasOne(f => f.Restaurant)
                .WithMany()
                .HasForeignKey(f => f.RestaurantId)
                .OnDelete(DeleteBehavior.NoAction);

            // FavouriteItem
            modelBuilder.Entity<FavouriteItem>()
                .HasOne(fi => fi.User)
                .WithMany()
                .HasForeignKey(fi => fi.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<FavouriteItem>()
                .HasOne(fi => fi.MenuItem)
                .WithMany()
                .HasForeignKey(fi => fi.MenuItemId)
                .OnDelete(DeleteBehavior.NoAction);

            // MonthlyOffer
            modelBuilder.Entity<MonthlyOffer>()
                .HasOne(mo => mo.Restaurant)
                .WithMany()
                .HasForeignKey(mo => mo.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);

            // UserMonthlyOffer
            modelBuilder.Entity<UserMonthlyOffer>()
                .HasOne(umo => umo.User)
                .WithMany()
                .HasForeignKey(umo => umo.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<UserMonthlyOffer>()
                .HasOne(umo => umo.MonthlyOffer)
                .WithMany()
                .HasForeignKey(umo => umo.MonthlyOfferId)
                .OnDelete(DeleteBehavior.NoAction);

            // Notification
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // DiscoveredRestaurant
            modelBuilder.Entity<DiscoveredRestaurant>()
                .HasOne(dr => dr.User)
                .WithMany()
                .HasForeignKey(dr => dr.UserId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<DiscoveredRestaurant>()
                .HasOne(dr => dr.Restaurant)
                .WithMany()
                .HasForeignKey(dr => dr.RestaurantId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}