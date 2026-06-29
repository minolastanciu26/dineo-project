using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DiscoveredController : ControllerBase
    {
        private readonly DineoContext _context;

        public DiscoveredController(DineoContext context)
        {
            _context = context;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetDiscovered(int userId)
        {
            var discoveredRestaurantIds = await _context.Orders
                .Where(o => o.UserId == userId && o.Status == "Paid" && o.ReservationId != null)
                .Select(o => o.RestaurantId)
                .Distinct()
                .ToListAsync();

            var allRestaurants = await _context.Restaurants
                .Where(r => r.Latitude != null && r.Longitude != null)
                .Select(r => new
                {
                    r.Id,
                    r.Name,
                    r.CuisineType,
                    r.Address,
                    r.ImageUrl,
                    r.Rating,
                    r.Latitude,
                    r.Longitude,
                    IsDiscovered = discoveredRestaurantIds.Contains(r.Id)
                })
                .ToListAsync();

            var discoveredCount = allRestaurants.Count(r => r.IsDiscovered);
            var totalCount = await _context.Restaurants.CountAsync();

            return Ok(new
            {
                allRestaurants,
                discoveredCount,
                totalCount,
                percentage = totalCount > 0
                    ? Math.Round((double)discoveredCount / totalCount * 100, 1)
                    : 0
            });
        }
    }
}