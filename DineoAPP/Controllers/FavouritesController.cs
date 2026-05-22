using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavouritesController : ControllerBase
    {
        private readonly DineoContext _context;

        public FavouritesController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/favourites/{userId}
        [HttpGet("{userId}")]
        public async Task<IActionResult> GetFavourites(int userId)
        {
            var favourites = await _context.Favourites
                .Where(f => f.UserId == userId)
                .Include(f => f.Restaurant)
                .Select(f => f.Restaurant)
                .ToListAsync();

            return Ok(favourites);
        }

        // POST: api/favourites
        [HttpPost]
        public async Task<IActionResult> AddFavourite([FromBody] FavouriteRequest request)
        {
            var exists = await _context.Favourites
                .AnyAsync(f => f.UserId == request.UserId && f.RestaurantId == request.RestaurantId);

            if (exists)
                return BadRequest(new { message = "Already in favourites" });

            var favourite = new Favourite
            {
                UserId = request.UserId,
                RestaurantId = request.RestaurantId,
                CreatedAt = DateTime.UtcNow
            };

            _context.Favourites.Add(favourite);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Added to favourites" });
        }

        // DELETE: api/favourites
        [HttpDelete]
        public async Task<IActionResult> RemoveFavourite([FromBody] FavouriteRequest request)
        {
            var favourite = await _context.Favourites
                .FirstOrDefaultAsync(f => f.UserId == request.UserId && f.RestaurantId == request.RestaurantId);

            if (favourite == null)
                return NotFound(new { message = "Not in favourites" });

            _context.Favourites.Remove(favourite);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Removed from favourites" });
        }

        // GET: api/favourites/{userId}/check/{restaurantId}
        [HttpGet("{userId}/check/{restaurantId}")]
        public async Task<IActionResult> CheckFavourite(int userId, int restaurantId)
        {
            var exists = await _context.Favourites
                .AnyAsync(f => f.UserId == userId && f.RestaurantId == restaurantId);

            return Ok(new { isFavourite = exists });
        }
    }

    public class FavouriteRequest
    {
        public int UserId { get; set; }
        public int RestaurantId { get; set; }
    }
}