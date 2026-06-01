using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TablesController : ControllerBase
    {
        private readonly DineoContext _context;

        public TablesController(DineoContext context)
        {
            _context = context;
        }

        // GET: api/tables/restaurant/5
        [HttpGet("restaurant/{restaurantId}")]
        public async Task<IActionResult> GetByRestaurant(int restaurantId)
        {
            var tables = await _context.Tables
                .Where(t => t.RestaurantId == restaurantId)
                .OrderBy(t => t.TableNumber)
                .ToListAsync();

            return Ok(tables);
        }

        // POST: api/tables
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Table table)
        {
            _context.Tables.Add(table);
            await _context.SaveChangesAsync();
            return Ok(table);
        }

        // PUT: api/tables/5
[HttpPut("{id}")]
public async Task<IActionResult> Update(int id, [FromBody] Table updated)
{
    var table = await _context.Tables.FindAsync(id);

    if (table == null)
        return NotFound(new { message = "Table not found!" });

    table.TableNumber = updated.TableNumber;
    table.Seats       = updated.Seats;
    table.Floor       = updated.Floor;
    table.PositionX   = updated.PositionX;
    table.PositionY   = updated.PositionY;
    // Nu atingem RestaurantId sau Restaurant navigation property

    await _context.SaveChangesAsync();
    return Ok(table);
}

        // DELETE: api/tables/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var table = await _context.Tables.FindAsync(id);

            if (table == null)
                return NotFound(new { message = "Table not found!" });

            _context.Tables.Remove(table);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Table deleted!" });
        }
    }
}