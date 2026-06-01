using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MenuCategoriesController : ControllerBase
    {
        private readonly DineoContext _context;

        public MenuCategoriesController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/menucategories/restaurant/5
        [HttpGet("restaurant/{restaurantId}")]
        public async Task<IActionResult> GetByRestaurant(int restaurantId)
        {
            var categories = await _context.MenuCategories
                .Where(c => c.RestaurantId == restaurantId)
                .Include(c => c.MenuItems)
                .ToListAsync();

            return Ok(categories);
        }

        // POST: api/menucategories
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MenuCategory category)
        {
            _context.MenuCategories.Add(category);
            await _context.SaveChangesAsync();
            return Ok(category);
        }

        // DELETE: api/menucategories/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var category = await _context.MenuCategories
                .Include(c => c.MenuItems)
                .FirstOrDefaultAsync(c => c.Id == id);

            if (category == null)
                return NotFound(new { message = "Category not found!" });

            _context.MenuCategories.Remove(category);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Category deleted!" });
        }
    }
}