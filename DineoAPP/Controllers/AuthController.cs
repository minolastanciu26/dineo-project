using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using DineoAPP.Data;
using DineoAPP.Models;

namespace DineoAPP.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly DineoContext _context;

        public AuthController(DineoContext context)
        {
            _context = context;
        }

        // Aceasta este adresa unde va suna iPhone-ul: POST api/auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] User loginData)
        {
            // Căutăm în baza de date un user cu acest email și această parolă
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == loginData.Email && u.Password == loginData.Password);

            if (user == null)
            {
                return Unauthorized("Email sau parolă greșită!");
            }

            return Ok(new { message = "Login reușit!", userId = user.Id });
        }
    }
}