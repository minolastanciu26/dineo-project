using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MenuItemsController : ControllerBase
    {
        private readonly DineoContext _context;

        public MenuItemsController(DineoContext context)
        {
            _context = context;
        }

        // POST: api/menuitems
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] MenuItemRequest request)
        {
            var item = new MenuItem
            {
                CategoryId  = request.CategoryId,
                Name        = request.Name,
                Description = request.Description,
                Price       = request.Price,
                ImageUrl    = request.ImageUrl,
                IsAvailable = true
            };

            _context.MenuItems.Add(item);
            await _context.SaveChangesAsync();
            return Ok(item);
        }

        // PUT: api/menuitems/5
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] MenuItemRequest request)
        {
            var item = await _context.MenuItems.FindAsync(id);

            if (item == null)
                return NotFound(new { message = "Item not found!" });

            item.Name        = request.Name;
            item.Description = request.Description;
            item.Price       = request.Price;
            item.ImageUrl    = request.ImageUrl;
            item.IsAvailable = request.IsAvailable;

            await _context.SaveChangesAsync();
            return Ok(item);
        }

        // DELETE: api/menuitems/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var item = await _context.MenuItems.FindAsync(id);

            if (item == null)
                return NotFound(new { message = "Item not found!" });

            _context.MenuItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Item deleted!" });
        }
    }

    public class MenuItemRequest
    {
        public int CategoryId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsAvailable { get; set; } = true;
    }
}