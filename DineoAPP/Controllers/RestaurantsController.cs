using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RestaurantsController : ControllerBase
    {
        private readonly DineoContext _context;

        public RestaurantsController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/restaurants
        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] string? search)
        {
            var query = _context.Restaurants.AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(r =>
                    r.Name.Contains(search) ||
                    r.CuisineType!.Contains(search) ||
                    r.Address!.Contains(search));
            }

            var restaurants = await query.ToListAsync();
            return Ok(restaurants);
        }

        // GET: api/restaurants/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var restaurant = await _context.Restaurants
                .Include(r => r.MenuCategories!)
                    .ThenInclude(c => c.MenuItems)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (restaurant == null)
                return NotFound(new { message = "Restaurantul nu există!" });

            return Ok(restaurant);
        }

        // GET: api/restaurants/top-rated
        [HttpGet("top-rated")]
        public async Task<IActionResult> GetTopRated()
        {
            var restaurants = await _context.Restaurants
                .OrderByDescending(r => r.Rating)
                .Take(10)
                .ToListAsync();

            return Ok(restaurants);
        }

        // GET: api/restaurants/new
        [HttpGet("new")]
        public async Task<IActionResult> GetNew()
        {
            var restaurants = await _context.Restaurants
                .OrderByDescending(r => r.CreatedAt)
                .Take(10)
                .ToListAsync();

            return Ok(restaurants);
        }

        // POST: api/restaurants (doar pentru admin)
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Restaurant restaurant)
        {
            restaurant.CreatedAt = DateTime.UtcNow;
            _context.Restaurants.Add(restaurant);
            await _context.SaveChangesAsync();
            return Ok(restaurant);
        }
    }
}