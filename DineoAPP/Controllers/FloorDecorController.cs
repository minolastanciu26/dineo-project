using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FloorDecorController : ControllerBase
    {
        private readonly DineoContext _context;

        public FloorDecorController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/floordecor/restaurant/5
        [HttpGet("restaurant/{restaurantId}")]
        public async Task<IActionResult> GetByRestaurant(int restaurantId)
        {
            var decors = await _context.FloorDecors
                .Where(d => d.RestaurantId == restaurantId)
                .ToListAsync();

            return Ok(decors);
        }

        // POST: api/floordecor
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] FloorDecor decor)
        {
            _context.FloorDecors.Add(decor);
            await _context.SaveChangesAsync();
            return Ok(decor);
        }

        // PUT: api/floordecor/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] FloorDecor updated)
        {
            var decor = await _context.FloorDecors.FindAsync(id);
            if (decor == null)
                return NotFound();

            decor.X = updated.X;
            decor.Y = updated.Y;

            await _context.SaveChangesAsync();
            return Ok(decor);
        }

        // DELETE: api/floordecor/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var decor = await _context.FloorDecors.FindAsync(id);
            if (decor == null)
                return NotFound();

            _context.FloorDecors.Remove(decor);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Deleted!" });
        }

        // DELETE: api/floordecor/restaurant/5/all
        [HttpDelete("restaurant/{restaurantId}/all")]
        public async Task<IActionResult> DeleteAll(int restaurantId)
        {
            var decors = await _context.FloorDecors
                .Where(d => d.RestaurantId == restaurantId)
                .ToListAsync();

            _context.FloorDecors.RemoveRange(decors);
            await _context.SaveChangesAsync();
            return Ok(new { message = "All decor cleared!" });
        }
    }
}