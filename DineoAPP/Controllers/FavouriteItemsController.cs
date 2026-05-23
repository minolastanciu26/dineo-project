using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavouriteItemsController : ControllerBase
    {
        private readonly DineoContext _context;

        public FavouriteItemsController(DineoContext context)
        {
            _context = context;
        }

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetFavouriteItems(int userId)
        {
            var items = await _context.FavouriteItems
                .Where(f => f.UserId == userId)
                .Include(f => f.MenuItem)
                .Select(f => f.MenuItem)
                .ToListAsync();

            return Ok(items);
        }

        [HttpGet("{userId}/restaurant/{restaurantId}")]
        public async Task<IActionResult> GetFavouriteItemsByRestaurant(int userId, int restaurantId)
        {
            var items = await _context.FavouriteItems
                .Where(f => f.UserId == userId)
                .Include(f => f.MenuItem)
                    .ThenInclude(mi => mi.Category)
                .Where(f => f.MenuItem.Category.RestaurantId == restaurantId)
                .Select(f => f.MenuItem)
                .ToListAsync();

            return Ok(items);
        }

        [HttpPost]
        public async Task<IActionResult> AddFavouriteItem([FromBody] FavouriteItemRequest request)
        {
            var exists = await _context.FavouriteItems
                .AnyAsync(f => f.UserId == request.UserId && f.MenuItemId == request.MenuItemId);

            if (exists)
                return BadRequest(new { message = "Already in favourites" });

            var item = new FavouriteItem
            {
                UserId = request.UserId,
                MenuItemId = request.MenuItemId,
                CreatedAt = DateTime.UtcNow
            };

            _context.FavouriteItems.Add(item);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Added to favourites" });
        }

        [HttpDelete]
        public async Task<IActionResult> RemoveFavouriteItem([FromBody] FavouriteItemRequest request)
        {
            var item = await _context.FavouriteItems
                .FirstOrDefaultAsync(f => f.UserId == request.UserId && f.MenuItemId == request.MenuItemId);

            if (item == null)
                return NotFound(new { message = "Not in favourites" });

            _context.FavouriteItems.Remove(item);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Removed from favourites" });
        }

        [HttpGet("{userId}/check/{menuItemId}")]
        public async Task<IActionResult> CheckFavouriteItem(int userId, int menuItemId)
        {
            var exists = await _context.FavouriteItems
                .AnyAsync(f => f.UserId == userId && f.MenuItemId == menuItemId);

            return Ok(new { isFavourite = exists });
        }
    }

    public class FavouriteItemRequest
    {
        public int UserId { get; set; }
        public int MenuItemId { get; set; }
    }
}